------------------------------------------------------------------------
----                                                                ----
---- WF68K30L IP Core: this is the bus controller module.           ----
----                                                                ----
---- Description:                                                   ----
---- This module is a 68030 compatible instruction word decoder.    ----
---- all of the 68030 bus interface functionality.                  ----
---- Besides the 68030 instructions this deoder features the follo- ----
---- wing ones:                                                     ----
----                                                                ----
---- This module is primarily controlled by the following signals:  ----
---- OW_REQ, OPD_ACK_xxx, EW_REQ, EW_ACK. The handshaking is as     ----
---- follows: if a new instruction is required, assert the signal   ----
---- OW_REQ and wait until ACK is asserted by the logic of          ----
---- the decoder logic. Deassert OW_REQ right after ACK             ----
---- (in the same clock cycle). One clock cycle after ACK, the      ----
---- required instruction has been copied from the pipe to the      ----
---- register BIW_0. The respective additional instruction words    ----
---- are located in BIW_1, BIW_2. For more information              ----
---- see the 68030 "Programmers Reference Manual" and the signal    ----
---- INSTR_LVL in this module.                                      ----
---- The extension request works in the same manner by asserting    ----
---- EW_REQ. One clock cycle after EXT_ACK one extension word has   ----
---- been copied to EXT_WORD.                                       ----
---- Be aware that it is in the scope of the logic driving          ----
---- OW_REQ and EW_REQ to hold the instruction pipe aligned.        ----
---- This means in detail, that the correct number or instruction   ----
---- and extension words must be requested. Otherwise unpredictable ----
---- processor behaviour will occur. Furthermore OW_REQ and         ----
---- EW_REQ may not be asserted the same time.                      ----
---- This operation code decoder with the handhsake logic as des-   ----
---- cribed above is the first pipeline stage of the CPU architec-  ----
---- ture.                                                          ----
----                                                                ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2014 Wolfgang Foerster Inventronik GmbH.           ----
----                                                                ----
---- This documentation describes Open Hardware and is licensed     ----
---- under the CERN OHL v. 1.2. You may redistribute and modify     ----
---- this documentation under the terms of the CERN OHL v.1.2.      ----
---- (http://ohwr.org/cernohl). This documentation is distributed   ----
---- WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING OF          ----
---- MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A        ----
---- PARTICULAR PURPOSE. Please see the CERN OHL v.1.2 for          ----
---- applicable conditions                                          ----
----                                                                ----
------------------------------------------------------------------------
-- 
-- Revision History
-- 
-- Revision 2K14B 20141201 WF
--   Initial Release.
-- 

use work.WF68K30L_PKG.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF68K30L_OPCODE_DECODER is
    port (
        CLK                 : in std_logic;

        OW_REQ_MAIN         : in bit; -- Request from the execution unit.
        EW_REQ_MAIN         : in bit; -- Extension words request.
        BUSY_EXH            : in bit; -- Exception handler is busy.
        BUSY_MAIN           : in bit; -- Main controller busy.
        BUSY_OPD            : out bit; -- This unit is busy.
        
        BKPT_DATA           : in std_logic_vector(15 downto 0);
        BKPT_INSERT         : in bit;

        OPD_ACK_MAIN        : out bit; -- Operation controller acknowledge.
        EW_ACK              : out bit; -- Extension word available.

        ADR_IN_PC_1         : in std_logic;
        PC_INC              : out bit;
        PC_INC_EXH          : in bit;
        PC_ADR_OFFSET       : out std_logic_vector(7 downto 0);
        PC_EW_OFFSET        : out std_logic_vector(2 downto 0);
        PC_OFFSET           : out std_logic_vector(7 downto 0);

        OPCODE_RD           : out bit;
        OPCODE_RDY          : in bit;
        OPCODE_VALID        : in std_logic;
        OPCODE_DATA         : in std_logic_vector(15 downto 0);

        IPIPE_FLUSH         : in bit; -- Abandon the instruction pipe.

        -- Fault logic:
        OW_VALID            : out std_logic; -- Operation words valid.
        RC                  : out std_logic; -- Rerun flag on instruction pipe stage C.
        RB                  : out std_logic; -- Rerun flag on instruction pipe stage B.
        FC                  : out std_logic; -- Fault on use of instruction pipe stage C.
        FB                  : out std_logic; -- Fault on use of instruction pipe stage B.

        -- Trap logic:
        SBIT                : in std_logic;
        TRAP_CODE           : out TRAPTYPE_OPC;

        -- System control signals:
        OP                  : out OP_68K;
        BIW_0               : out std_logic_vector(15 downto 0);
        BIW_1               : out std_logic_vector(15 downto 0);
        BIW_2               : out std_logic_vector(15 downto 0);
        EXT_WORD            : out std_logic_vector(15 downto 0);

        REST_BIW_0          : in bit
    );
end entity WF68K30L_OPCODE_DECODER;

architecture BEHAVIOR of WF68K30L_OPCODE_DECODER is
type CAHR_STATUSTYPE is(FULL, EMPTY);
type INSTR_LVL_TYPE is(D, B, C);
type IPIPE_TYPE is
    record
        D       : std_logic_vector(15 downto 0);
        C       : std_logic_vector(15 downto 0);
        B       : std_logic_vector(15 downto 0);
    end record;

signal REQ                  : bit;

signal CAHR                 : std_logic_vector(15 downto 0);
signal CAHR_REQ             : bit;
signal CAHR_FAULT           : std_logic;
signal CAHR_STATUS          : CAHR_STATUSTYPE;

signal EW_REQ               : bit;

signal IPIPE                : IPIPE_TYPE;
signal FIFO_RD              : bit;
signal IPIPE_B_FAULT        : std_logic;
signal IPIPE_C_FAULT        : std_logic;
signal IPIPE_D_FAULT        : std_logic;
signal IPIPE_PNTR           : natural range 0 to 3;

signal INSTR_LVL            : INSTR_LVL_TYPE;

signal BKPT_REQ             : bit;

signal OP_I                 : OP_68K;

signal OPCODE_RD_I          : bit;
signal OW_REQ               : bit;

signal TRAP_CODE_I          : TRAPTYPE_OPC;
signal FLUSHED              : boolean;
signal PC_INC_I             : bit;
signal PIPE_RDY             : bit;
begin
    P_BSY: process(BUSY_EXH, CLK, IPIPE_FLUSH, OPCODE_RDY)
    -- This logic requires asynchronous reset. This flip flop is intended 
    -- to break combinatorial loops. If an opcode cycle in the bus controller 
    -- unit is currently running, the actual PC address is stored during this 
    -- cycle. Therefore it is not possible to flush the pipe and manipulate 
    -- the PC during a running cycle. For the exception handler reading the 
    -- opcode is inhibited during a pipe flush. For the main controller unit 
    -- and the coprocessor interface the pipe is flushed after a running 
    -- opcode cycle.
    begin
        if OPCODE_RDY = '1' then
            OPCODE_RD_I <= '0';
        elsif BUSY_EXH = '1' and IPIPE_FLUSH = '1' then
            OPCODE_RD_I <= '0';
        elsif CLK = '1' and CLK' event then
            if IPIPE_FLUSH = '1' then
                OPCODE_RD_I <= '1';
            elsif CAHR_STATUS = EMPTY then
                OPCODE_RD_I <= '1';
            end if;
        end if;
    end process P_BSY;

    OPCODE_RD <= OPCODE_RD_I;
    BUSY_OPD <= '1' when OPCODE_RD_I = '1' else '0';

    CAHR_REQ <= '0' when BKPT_REQ = '1' else -- Do not alter when BKPT is inserted.
                '1' when OW_REQ = '0' and EW_REQ = '0' and IPIPE_PNTR < 3 and CAHR_STATUS /= EMPTY else
                '1' when OW_REQ = '1' and CAHR_STATUS /= EMPTY else
                '1' when EW_REQ = '1' and CAHR_STATUS /= EMPTY else '0';

    P_CAHR: process
    -- This is the cache holding register. This register
    -- is considered as stage A of the instruction pipe
    -- but is 32 bit wide.
    -- Be aware, that the opcode is requested (OPCODE_RD) only
    -- in CAHR_STATUS = EMPTY. So if OPCODE_RDY is asserted
    -- the cache holding register is empty.
    begin
        wait until CLK = '1' and CLK' event;
        if IPIPE_FLUSH = '1' then
            CAHR <= (others => '0');
            CAHR_STATUS <= EMPTY;
        elsif OPCODE_RDY = '1' then
            if IPIPE_PNTR = 3 and OW_REQ = '0' then
                CAHR <= OPCODE_DATA;
                CAHR_STATUS <= FULL;
                CAHR_FAULT <= not OPCODE_VALID;
            end if;
        elsif CAHR_REQ = '1' then
            CAHR_STATUS <= EMPTY;
        end if;
    end process P_CAHR;

    INSTRUCTION_PIPE: process
    -- These are the instruction pipe FIFO registers. The opcodes are stored in IPIPE.B, IPIPE.C
    -- and IPIPE.D which is copied to the instruction register or to the respective extension when
    -- read. Be aware, that the pipe is always completely refilled to determine the correct INSTR_LVL
    -- before it is copied to the execution unit.
    variable IPIPE_D_VAR    : std_logic_vector(15 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        if IPIPE_FLUSH = '1' then
            IPIPE.D <= (others => '0');
            IPIPE.C <= (others => '0');
            IPIPE.B <= (others => '0');
            IPIPE_PNTR <= 0;
        elsif BKPT_INSERT = '1' then
            IPIPE_D_VAR := IPIPE.D;
            IPIPE.D <= BKPT_DATA; -- Insert the breakpoint data.
            BKPT_REQ <= '1';
        elsif OW_REQ = '1' and BKPT_REQ = '1' then
            IPIPE.D <= IPIPE_D_VAR; -- Restore from breakpoint.
            BKPT_REQ <= '0';
        elsif OW_REQ = '1' and INSTR_LVL = D and PIPE_RDY = '1' and IPIPE_PNTR = 2 then
            if OPCODE_RDY = '1' then
                IPIPE.D <= IPIPE.C;
                IPIPE.C <= OPCODE_DATA;
                IPIPE_D_FAULT <= IPIPE_C_FAULT;
                IPIPE_C_FAULT <= not OPCODE_VALID;
            elsif CAHR_STATUS /= EMPTY then
                IPIPE.D <= IPIPE.C;
                IPIPE.C <= CAHR;
                IPIPE_D_FAULT <= IPIPE_C_FAULT;
                IPIPE_C_FAULT <= CAHR_FAULT;
            else
                IPIPE.D <= IPIPE.C;
                IPIPE_D_FAULT <= IPIPE_C_FAULT;
                IPIPE_PNTR <= IPIPE_PNTR - 1;
            end if;
        elsif OW_REQ = '1' and INSTR_LVL = D and PIPE_RDY = '1' and IPIPE_PNTR = 3 then
            if OPCODE_RDY = '1' then
                IPIPE.D <= IPIPE.C;
                IPIPE.C <= IPIPE.B;
                IPIPE.B <= OPCODE_DATA;
                IPIPE_D_FAULT <= IPIPE_C_FAULT;
                IPIPE_C_FAULT <= IPIPE_B_FAULT;
                IPIPE_B_FAULT <= not OPCODE_VALID;
            elsif CAHR_STATUS /= EMPTY then
                IPIPE.D <= IPIPE.C;
                IPIPE.C <= IPIPE.B;
                IPIPE.B <= CAHR;
                IPIPE_D_FAULT <= IPIPE_C_FAULT;
                IPIPE_C_FAULT <= IPIPE_B_FAULT;
                IPIPE_B_FAULT <= CAHR_FAULT;
            else
                IPIPE.D <= IPIPE.C;
                IPIPE.C <= IPIPE.B;
                IPIPE_D_FAULT <= IPIPE_C_FAULT;
                IPIPE_C_FAULT <= IPIPE_B_FAULT;
                IPIPE_PNTR <= IPIPE_PNTR - 1;
            end if;
        elsif OW_REQ = '1' and INSTR_LVL = C and PIPE_RDY = '1' and IPIPE_PNTR = 2 then
            if OPCODE_RDY = '1' then
                IPIPE.D <= OPCODE_DATA;
                IPIPE_D_FAULT <= not OPCODE_VALID;
                IPIPE_PNTR <= IPIPE_PNTR - 1;
            elsif CAHR_STATUS /= EMPTY then
                IPIPE.B <= CAHR;
                IPIPE_D_FAULT <= CAHR_FAULT;
                IPIPE_PNTR <= IPIPE_PNTR - 1;
            else
                IPIPE_PNTR <= 0;
            end if;
        elsif OW_REQ = '1' and INSTR_LVL = C and PIPE_RDY = '1' and IPIPE_PNTR = 3 then
            if OPCODE_RDY = '1' then
                IPIPE.D <= IPIPE.B;
                IPIPE.C <= OPCODE_DATA;
                IPIPE_D_FAULT <= IPIPE_B_FAULT;
                IPIPE_C_FAULT <= not OPCODE_VALID;
                IPIPE_PNTR <= IPIPE_PNTR - 1;
            elsif CAHR_STATUS /= EMPTY then
                IPIPE.D <= IPIPE.B;
                IPIPE.C <= CAHR;
                IPIPE_D_FAULT <= IPIPE_B_FAULT;
                IPIPE_C_FAULT <= CAHR_FAULT;
                IPIPE_PNTR <= IPIPE_PNTR - 1;
            else
                IPIPE.D <= IPIPE.B;
                IPIPE_D_FAULT <= IPIPE_B_FAULT;
                IPIPE_PNTR <= IPIPE_PNTR - 2;
            end if;
        elsif OW_REQ = '1' and INSTR_LVL = B and PIPE_RDY = '1' then -- IPIPE_PNTR = 3.
            if OPCODE_RDY = '1' then
                IPIPE.D <= OPCODE_DATA;
                IPIPE_D_FAULT <= not OPCODE_VALID;
                IPIPE_PNTR <= IPIPE_PNTR - 2;
            elsif CAHR_STATUS /= EMPTY then
                IPIPE.D <= CAHR;
                IPIPE_D_FAULT <= CAHR_FAULT;
                IPIPE_PNTR <= IPIPE_PNTR - 2;
            else
                IPIPE_PNTR <= 0;
            end if;
        elsif EW_REQ = '1' and IPIPE_PNTR >= 1 then
            case IPIPE_PNTR is
                when 3 =>
                    if OPCODE_RDY = '1' then
                        IPIPE.D <= IPIPE.C;
                        IPIPE.C <= IPIPE.B;
                        IPIPE.B <= OPCODE_DATA;
                        IPIPE_D_FAULT <= IPIPE_C_FAULT;
                        IPIPE_C_FAULT <= IPIPE_B_FAULT;
                        IPIPE_B_FAULT <= not OPCODE_VALID;
                    elsif CAHR_STATUS /= EMPTY then
                        IPIPE.D <= IPIPE.C;
                        IPIPE.C <= IPIPE.B;
                        IPIPE.B <= CAHR;
                        IPIPE_D_FAULT <= IPIPE_C_FAULT;
                        IPIPE_C_FAULT <= IPIPE_B_FAULT;
                        IPIPE_B_FAULT <= CAHR_FAULT;
                    else
                        IPIPE.D <= IPIPE.C;
                        IPIPE.C <= IPIPE.B;
                        IPIPE_D_FAULT <= IPIPE_C_FAULT;
                        IPIPE_C_FAULT <= IPIPE_B_FAULT;
                        IPIPE_PNTR <= IPIPE_PNTR - 1;
                    end if;
                when 2 =>
                    if OPCODE_RDY = '1' then
                        IPIPE.D <= IPIPE.C;
                        IPIPE.C <= OPCODE_DATA;
                        IPIPE_D_FAULT <= IPIPE_C_FAULT;
                        IPIPE_C_FAULT <= not OPCODE_VALID;
                    elsif CAHR_STATUS /= EMPTY then
                        IPIPE.D <= IPIPE.C;
                        IPIPE.C <= CAHR;
                        IPIPE_D_FAULT <= IPIPE_C_FAULT;
                        IPIPE_C_FAULT <= CAHR_FAULT;
                    else
                        IPIPE.D <= IPIPE.C;
                        IPIPE_D_FAULT <= IPIPE_C_FAULT;
                        IPIPE_PNTR <= IPIPE_PNTR - 1;
                    end if;
                when 1 =>
                    if OPCODE_RDY = '1' then
                        IPIPE.D <= OPCODE_DATA;
                        IPIPE_D_FAULT <= not OPCODE_VALID;
                    elsif CAHR_STATUS /= EMPTY then
                        IPIPE.D <= CAHR;
                        IPIPE_D_FAULT <= CAHR_FAULT;
                    else
                        IPIPE_PNTR <= 0;
                    end if;
                when others => null;
            end case;
        elsif OPCODE_RDY = '1' then
            case IPIPE_PNTR is
                when 2 =>
                    IPIPE.B <= OPCODE_DATA;
                    IPIPE_B_FAULT <= not OPCODE_VALID;
                    IPIPE_PNTR <= 3;
                when 1 =>
                    IPIPE.C <= OPCODE_DATA;
                    IPIPE_C_FAULT <= not OPCODE_VALID;
                    IPIPE_PNTR <= 2;
                when 0 =>
                    IPIPE.D <= OPCODE_DATA;
                    IPIPE_D_FAULT <= not OPCODE_VALID;
                    IPIPE_PNTR <= 1;
                when others => null;
            end case;
        elsif IPIPE_PNTR < 3 and CAHR_STATUS /= EMPTY then -- Shift but no read results in filling.
            case IPIPE_PNTR is
                when 0 =>
                    IPIPE.D <= CAHR;
                    IPIPE_D_FAULT <= CAHR_FAULT;
                when 1 =>
                    IPIPE.C <= CAHR;
                    IPIPE_C_FAULT <= CAHR_FAULT;
                when 2 | 3 => -- 3 is overflow!
                    IPIPE.B <= CAHR;
                    IPIPE_B_FAULT <= CAHR_FAULT;
            end case;
            IPIPE_PNTR <= IPIPE_PNTR + 1;
        end if;
    end process INSTRUCTION_PIPE;

    P_FAULT: process
    -- This are the fault flags for pipe B and C.
    -- These flags are set, when an instruction
    -- request uses either of the respective pipes.
    begin
        wait until CLK = '1' and CLK' event;
        if IPIPE_FLUSH = '1' then
            OW_VALID <= '0';
            FC <= '0';
            FB <= '0';
        elsif OW_REQ = '1' and PIPE_RDY = '1' and INSTR_LVL = D then
            OW_VALID <= not IPIPE_D_FAULT;
            FC <= '0';
            FB <= '0';
        elsif OW_REQ = '1' and PIPE_RDY = '1' and INSTR_LVL = C then
            OW_VALID <= not(IPIPE_D_FAULT or IPIPE_C_FAULT);
            FC <= IPIPE_C_FAULT;
            FB <= '0';
        elsif OW_REQ = '1' and PIPE_RDY = '1' and INSTR_LVL = B then
            OW_VALID <= not (IPIPE_D_FAULT or IPIPE_C_FAULT or IPIPE_B_FAULT);
            FC <= IPIPE_C_FAULT;
            FB <= IPIPE_B_FAULT;
        elsif EW_REQ = '1' and PIPE_RDY = '1' then
            OW_VALID <= not IPIPE_D_FAULT;
            FC <= '0';
            FB <= '0';
        end if;
        -- The Rerun Flags:
        if IPIPE_FLUSH = '1' then
            RC <= '0';
            RB <= '0';
        elsif (EW_REQ or OW_REQ) = '1' and PIPE_RDY = '1' then
            RC <= IPIPE_C_FAULT;
            RB <= IPIPE_B_FAULT;
        end if;
        -- Restoring:
        if REST_BIW_0 = '1' then
            OW_VALID <= '1'; -- Used by RTE.
        end if;
    end process P_FAULT;

    OUTBUFFERS: process
    variable OP_STOP    : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if OP_STOP = true and IPIPE_FLUSH = '1' then
            TRAP_CODE <= NONE;
            OP_STOP := false;
        elsif IPIPE_FLUSH = '1' then
            TRAP_CODE <= NONE;
        elsif OP_STOP = true then
            null; -- Do not update after PC is incremented.
        elsif OW_REQ = '1' and (PIPE_RDY = '1' or BKPT_REQ = '1') then
            -- Be aware: all BIW are written unaffected 
            -- if they are all used.
            OP <= OP_I;
            BIW_0 <= IPIPE.D;
            BIW_1 <= IPIPE.C;
            BIW_2 <= IPIPE.B;
            TRAP_CODE <= TRAP_CODE_I;
            --
            if OP_I = STOP then
                OP_STOP := true;
            end if;
        elsif EW_REQ = '1' and IPIPE_PNTR /= 0 then
            EXT_WORD <= IPIPE.D;
        end if;
        --
        if REST_BIW_0 = '1' then
            BIW_0 <= OPCODE_DATA; -- Used by RTE.
        end if;
        --
    end process OUTBUFFERS;

    OW_REQ <= '0' when BUSY_EXH = '1' else OW_REQ_MAIN;

    EW_REQ <= EW_REQ_MAIN;

    PIPE_RDY <= '1' when OW_REQ = '1' and IPIPE_PNTR = 3 and INSTR_LVL = B else
                '1' when OW_REQ = '1' and IPIPE_PNTR > 1 and INSTR_LVL = C else
                '1' when OW_REQ = '1' and IPIPE_PNTR > 1 and INSTR_LVL = D else -- We need always pipe C and D to determine the INSTR_LVL.
                '1' when EW_REQ = '1' and IPIPE_PNTR > 0 else '0';
 
    HANDSHAKING: process
    -- Wee need these flip flops to ensure, that the OUTBUFFERS are
    -- written when the respecktive _ACK signal is asserted.
    -- The breakpoint cycles are valid for one word operations and
    -- therefore does never start FPU operations.
    begin
        wait until CLK = '1' and CLK' event;
        if EW_REQ = '1' and IPIPE_PNTR /= 0 then
            EW_ACK <= '1';
        else
            EW_ACK <= '0';
        end if;

        if IPIPE_FLUSH = '1' then
            OPD_ACK_MAIN <= '0';
        elsif TRAP_CODE_I = T_PRIV then -- No action when priviledged.
            OPD_ACK_MAIN <= '0';
        elsif OW_REQ = '1' and (PIPE_RDY = '1' or BKPT_REQ = '1') then
            OPD_ACK_MAIN <= '1';
        else
            OPD_ACK_MAIN <= '0';
        end if;
    end process HANDSHAKING;

    P_PC_OFFSET: process(CLK, PC_INC_EXH, PC_INC_I)
    -- Be Aware: the ADR_OFFSET requires the 'old' PC_VAR.
    -- To arrange this, the ADR_OFFSET logic is located
    -- above the PC_VAR logic. Do not change this!
    -- The PC_VAR is modeled in a way, that the PC points
    -- always to the BIW_0.
    -- The PC_EW_OFFSET is also used for the calculation 
    -- of the correct PC value written to the stack pointer
    -- during BSR, JSR and exceptions.
    variable ADR_OFFSET     : std_logic_vector(6 downto 0);
    variable PC_VAR         : std_logic_vector(6 downto 0);
    variable PC_VAR_MEM     : std_logic_vector(6 downto 0);
    begin
        if CLK = '1' and CLK' event then
            if IPIPE_FLUSH = '1' then
                ADR_OFFSET := "0000000";
            elsif PC_INC_I = '1' and OPCODE_RDY = '1' then
                ADR_OFFSET := ADR_OFFSET + '1' - PC_VAR;
            elsif OPCODE_RDY = '1' then
                ADR_OFFSET := ADR_OFFSET + '1';
            elsif PC_INC_I = '1' then
                ADR_OFFSET := ADR_OFFSET - PC_VAR;
            end if;
            --
            if BUSY_EXH = '0' then
                PC_VAR_MEM := PC_VAR; -- Store the old offset to write back on the stack.
            end if;

            if BUSY_EXH = '1' then
                -- New PC is loaded by the exception handler.
                -- So PC_VAR must be initialized.
                PC_VAR := "0000000";
            elsif PC_INC_I = '1' or FLUSHED = true then
                case INSTR_LVL is
                    when D => PC_VAR := "0000001";
                    when C => PC_VAR := "0000010";
                    when B => PC_VAR := "0000011";
                end case;
            elsif EW_REQ = '1' and IPIPE_PNTR /= 0 then
                PC_VAR := PC_VAR + '1';
            end if;
            --
            if OW_REQ = '1' and BKPT_REQ = '1' then
                PC_EW_OFFSET <= "010"; -- Always level D operations.
            elsif OW_REQ = '1' and PIPE_RDY = '1' then
                case INSTR_LVL is
                    when D => PC_EW_OFFSET <= "010";
                    when C => PC_EW_OFFSET <= "100";
                    when others => PC_EW_OFFSET <= "110"; -- LONG displacement.
                end case;
            end if;
        end if;
        --
        if PC_INC_EXH = '1' then
            PC_OFFSET <= PC_VAR_MEM & '0';
        else
            PC_OFFSET <= PC_VAR & '0';
        end if;
        PC_ADR_OFFSET <= ADR_OFFSET & '0';
    end process P_PC_OFFSET;

    P_FLUSH: process
    -- This flip flop is intended to control the incrementation
    -- of the PC. Normally the PC is updated in the end of an
    -- operation (if a new opword is available) or otherwise in
    -- the START_OP phase. When the instruction pipe is flushed,
    -- it is required to increment the PC immediately to provide
    -- the correct address for the pipe refilling. In this case
    -- the PC update after the pipe refill must be suppressed. 
    begin
        wait until CLK = '1' and CLK' event;
        if IPIPE_FLUSH = '1' and BUSY_EXH = '0' then
            FLUSHED <= true;
        elsif OW_REQ = '1' and PIPE_RDY = '1' then
            FLUSHED <= false;
        end if;
    end process P_FLUSH;

    PC_INC <= PC_INC_I; -- Do not change the prioritization of PC_INC_I.
    PC_INC_I <= '1' when IPIPE_FLUSH = '1' and BUSY_EXH = '0' else -- If the pipe is flushed, we need the new PC value for refilling.
                '0' when BKPT_REQ = '1' else -- Do not update!
                '0' when OW_REQ = '1' and PIPE_RDY = '1' and OP_I = UNIMPLEMENTED else -- Do not update!
                '1' when OW_REQ = '1' and PIPE_RDY = '1' and FLUSHED = false else '0';

    -- This signal indicates how many pipe stages are used at a time.
    -- Be aware: all coprocessor commands are level D to meet the require-
    -- ments of the scanPC.
    INSTR_LVL <= B when OP_I = ADDI and IPIPE.D(7 downto 6) = "10" else
                 B when OP_I = ANDI and IPIPE.D(7 downto 6) = "10" else
                 B when (OP_I = Bcc or OP_I = BRA or OP_I = BSR) and IPIPE.D(7 downto 0) = x"FF" else
                 B when OP_I = CAS2 or (OP_I = CMPI and IPIPE.D(7 downto 6) = "10") else
                 B when OP_I = EORI and IPIPE.D(7 downto 6) = "10" else
                 B when OP_I = LINK and IPIPE.D(11 downto 3) = "100000001" else -- LONG.
                 B when OP_I = ORI and IPIPE.D(7 downto 6) = "10" else
                 B when OP_I = SUBI and IPIPE.D(7 downto 6) = "10" else
                 B when OP_I = TRAPcc and IPIPE.D(2 downto 0) = "011" else
                 C when OP_I = ADDI or OP_I = ANDI or OP_I = ANDI_TO_SR or OP_I = ANDI_TO_CCR else
                 C when (OP_I = BCHG or OP_I = BCLR or OP_I = BSET or OP_I = BTST) and IPIPE.D(8) = '0' else
                 C when (OP_I = Bcc or OP_I = BRA or OP_I = BSR) and IPIPE.D(7 downto 0) = x"00" else
                 C when OP_I = BFCHG or OP_I = BFCLR or OP_I = BFEXTS or OP_I = BFEXTU else
                 C when OP_I = BFFFO or OP_I = BFINS or OP_I = BFSET or OP_I = BFTST else
                 C when OP_I = CAS or OP_I = CHK2 or OP_I = CMP2 or OP_I = CMPI or OP_I = DBcc else
                 C when (OP_I = DIVS or OP_I = DIVU) and IPIPE.D(8 downto 6) = "001" else
                 C when OP_I = EORI or OP_I = EORI_TO_CCR or OP_I = EORI_TO_SR else
                 C when OP_I = LINK or OP_I = MOVEC else
                 C when OP_I = MOVEM or OP_I = MOVEP or OP_I = MOVES else
                 C when (OP_I = MULS or OP_I = MULU) and IPIPE.D(8 downto 6) = "000" else
                 C when OP_I = ORI_TO_CCR or OP_I = ORI_TO_SR or OP_I = ORI else
                 C when OP_I = PACK else 
                 C when OP_I = RTD or OP_I = RTE or OP_I = SUBI or OP_I = STOP else
                 C when OP_I = TRAPcc and IPIPE.D(2 downto 0) = "010" else 
                 C when OP_I = UNPK else D;

    TRAP_CODE_I <= T_1010 when OP_I = UNIMPLEMENTED and IPIPE.D(15 downto 12) = "1010" else
                   T_1111 when OP_I = UNIMPLEMENTED and IPIPE.D(15 downto 9) = "1111000" else -- Not valid MMU patterns.
                   T_ILLEGAL when OP_I = ILLEGAL else 
                   T_TRAP when OP_I = TRAP else
                   T_PRIV when IPIPE.D(15 downto 9) = "1111000" and SBIT = '0' else -- MMU in user mode is not allowed.
                   T_PRIV when OP_I = ANDI_TO_SR and SBIT = '0' else 
                   T_PRIV when OP_I = EORI_TO_SR and SBIT = '0' else 
                   T_PRIV when (OP_I = MOVE_FROM_SR or OP_I = MOVE_TO_SR) and SBIT = '0' else 
                   T_PRIV when (OP_I = MOVE_USP or OP_I = MOVEC or OP_I = MOVES) and SBIT = '0' else 
                   T_PRIV when OP_I = ORI_TO_SR and SBIT = '0' else
                   T_PRIV when (OP_I = RESET or OP_I = RTE) and SBIT = '0' else 
                   T_PRIV when OP_I = STOP and SBIT = '0' else NONE;
            
    OP_DECODE: process(IPIPE)
    begin
        -- The default OPCODE is the ILLEGAL operation, if no of the following conditions are met.
        -- If any not used bit pattern occurs, the CPU will result in an ILLEGAL trap. An exception of
        -- this behavior is the OPCODE with the 1010 or the 1111 pattern in the four MSBs. 
        -- These lead to the respective traps.
        OP_I <= ILLEGAL;
        case IPIPE.D(15 downto 12) is -- Operation code map.
            when x"0" => -- Bit manipulation / MOVEP / Immediate.
                if IPIPE.D(11 downto 0) = x"03C" then
                    OP_I <= ORI_TO_CCR;
                elsif IPIPE.D(11 downto 0) = x"07C" then
                    OP_I <= ORI_TO_SR;
                elsif IPIPE.D(11 downto 0) = x"23C" then
                    OP_I <= ANDI_TO_CCR;
                elsif IPIPE.D(11 downto 0) = x"27C" then
                    OP_I <= ANDI_TO_SR;
                elsif IPIPE.D(11 downto 0) = x"A3C" then
                    OP_I <= EORI_TO_CCR;
                elsif IPIPE.D(11 downto 0) = x"A7C" then
                    OP_I <= EORI_TO_SR;
                elsif IPIPE.D(11 downto 0) = "110011111100" then
                    OP_I <= CAS2;
                elsif IPIPE.D(11 downto 0) = "111011111100" then
                    OP_I <= CAS2;
                elsif IPIPE.D(11 downto 8) = "1110" and IPIPE.D(7 downto 6) < "11" and IPIPE.D(5 downto 3) >= "010" and IPIPE.D(5 downto 3) < "111" then
                    OP_I <= MOVES;
                elsif IPIPE.D(11 downto 8) = "1110" and IPIPE.D(7 downto 6) < "11" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= MOVES;
                elsif IPIPE.D(8 downto 6) > "011" and IPIPE.D(5 downto 3) = "001" then
                    OP_I <= MOVEP;
                elsif IPIPE.D(11) = '0' and IPIPE.D(10 downto 9) /= "11" and IPIPE.D(8 downto 6) = "011" and IPIPE.D(5 downto 3) = "010" and IPIPE.C(11) = '1' then
                        OP_I <= CHK2;
                elsif IPIPE.D(11) = '0' and IPIPE.D(10 downto 9) /= "11" and IPIPE.D(8 downto 6) = "011" and IPIPE.D(5 downto 3) > "100" and IPIPE.D(5 downto 3) < "111" and IPIPE.C(11) = '1' then
                        OP_I <= CHK2;
                elsif IPIPE.D(11) = '0' and IPIPE.D(10 downto 9) /= "11" and IPIPE.D(8 downto 6) = "011" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "100" and IPIPE.C(11) = '1' then
                        OP_I <= CHK2;
                elsif IPIPE.D(11) = '0' and IPIPE.D(10 downto 9) /= "11" and IPIPE.D(8 downto 6) = "011" and IPIPE.D(5 downto 3) = "010" and IPIPE.C(11) = '0' then
                        OP_I <= CMP2;
                elsif IPIPE.D(11) = '0' and IPIPE.D(10 downto 9) /= "11" and IPIPE.D(8 downto 6) = "011" and IPIPE.D(5 downto 3) > "100" and IPIPE.D(5 downto 3) < "111" and IPIPE.C(11) = '0' then
                        OP_I <= CMP2;
                elsif IPIPE.D(11) = '0' and IPIPE.D(10 downto 9) /= "11" and IPIPE.D(8 downto 6) = "011" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "100" and IPIPE.C(11) = '0' then
                        OP_I <= CMP2;
                elsif IPIPE.D(11) = '1' and IPIPE.d(10 downto 9) /= "00" and IPIPE.D(8 downto 6) = "011" and IPIPE.D(5 downto 3) > "001" and IPIPE.D(5 downto 3) < "111" then
                    OP_I <= CAS;
                elsif IPIPE.D(11) = '1' and IPIPE.d(10 downto 9) /= "00" and IPIPE.D(8 downto 6) = "011" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= CAS;
                else
                    case IPIPE.D(5 downto 3) is -- Addressing mode.
                        when "000" | "010" | "011" | "100" | "101" | "110" =>
                            -- Bit operations with static bit number:
                            if IPIPE.D(11 downto 6) = "100000" then
                                OP_I <= BTST;
                            elsif IPIPE.D(11 downto 6) = "100001" then
                                OP_I <= BCHG;
                            elsif IPIPE.D(11 downto 6) = "100010" then
                                OP_I <= BCLR;
                            elsif IPIPE.D(11 downto 6) = "100011" then
                                OP_I <= BSET;
                            -- Logic operations:
                            elsif IPIPE.D(11 downto 8) = x"0" and IPIPE.D(7 downto 6) < "11" then
                                OP_I <= ORI;
                            elsif IPIPE.D(11 downto 8) = x"2" and IPIPE.D(7 downto 6) < "11" then
                                OP_I <= ANDI;
                            elsif IPIPE.D(11 downto 8) = x"4" and IPIPE.D(7 downto 6) < "11" then
                                OP_I <= SUBI;
                            elsif IPIPE.D(11 downto 8) = x"6" and IPIPE.D(7 downto 6) < "11" then
                                OP_I <= ADDI;
                            elsif IPIPE.D(11 downto 8) = x"A" and IPIPE.D(7 downto 6) < "11" then
                                OP_I <= EORI;
                            elsif IPIPE.D(11 downto 8) = x"C" and IPIPE.D(7 downto 6) < "11" then
                                OP_I <= CMPI;
                            -- Bit operations with dynamic bit number:
                            elsif IPIPE.D(8 downto 6) = "100" then
                                OP_I <= BTST;
                            elsif IPIPE.D(8 downto 6) = "101" then
                                OP_I <= BCHG;
                            elsif IPIPE.D(8 downto 6) = "110" then
                                OP_I <= BCLR;
                            elsif IPIPE.D(8 downto 6) = "111" then
                                OP_I <= BSET;
                            end if;
                        when "111" =>
                            -- In the addressing mode "111" not all register selections are valid.
                            -- Bit operations with static bit number:
                            if IPIPE.D(11 downto 6) = "100000" and IPIPE.D(2 downto 0) < "100" then
                                OP_I <= BTST;
                            elsif IPIPE.D(11 downto 6) = "100001" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= BCHG;
                            elsif IPIPE.D(11 downto 6) = "100010" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= BCLR;
                            elsif IPIPE.D(11 downto 6) = "100011" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= BSET;
                            -- Logic operations:
                            elsif IPIPE.D(11 downto 8) = x"0" and IPIPE.D(7 downto 6) < "11" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= ORI;
                            elsif IPIPE.D(11 downto 8) = x"2" and IPIPE.D(7 downto 6) < "11" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= ANDI;
                            elsif IPIPE.D(11 downto 8) = x"4" and IPIPE.D(7 downto 6) < "11" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= SUBI;
                            elsif IPIPE.D(11 downto 8) = x"6" and IPIPE.D(7 downto 6) < "11" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= ADDI;
                            elsif IPIPE.D(11 downto 8) = x"A" and IPIPE.D(7 downto 6) < "11" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= EORI;
                            elsif IPIPE.D(11 downto 8) = x"C" and IPIPE.D(7 downto 6) < "11" and IPIPE.D(2 downto 0) < "100" then
                                OP_I <= CMPI;
                            -- Bit operations with dynamic bit number:
                            elsif IPIPE.D(8 downto 6) = "100" and IPIPE.D(2 downto 0) < "101" then
                                OP_I <= BTST;
                            elsif IPIPE.D(8 downto 6) = "101" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= BCHG;
                            elsif IPIPE.D(8 downto 6) = "110" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= BCLR;
                            elsif IPIPE.D(8 downto 6) = "111" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= BSET;
                            end if;
                        when others =>
                            null;
                    end case;
                end if;
            when x"1" => -- Move BYTE.
                if IPIPE.D(8 downto 6) = "111" and IPIPE.D(11 downto 9) < "010"
                        and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                    OP_I <= MOVE;
                elsif IPIPE.D(8 downto 6) = "111" and IPIPE.D(11 downto 9) < "010" and IPIPE.D(5 downto 3) /= "001"  and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= MOVE;
                elsif IPIPE.D(8 downto 6) /= "001" and IPIPE.D(8 downto 6) /= "111" 
                        and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                    OP_I <= MOVE;
                elsif IPIPE.D(8 downto 6) /= "001" and IPIPE.D(8 downto 6) /= "111" and IPIPE.D(5 downto 3) /= "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= MOVE;
                end if;
            when x"2" | x"3" => -- Move WORD or LONG.
                if IPIPE.D(8 downto 6) = "111" and IPIPE.D(11 downto 9) < "010" 
                        and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                    OP_I <= MOVE;
                elsif IPIPE.D(8 downto 6) = "111" and IPIPE.D(11 downto 9) < "010" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= MOVE;
                elsif IPIPE.D(8 downto 6) = "001" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                    OP_I <= MOVEA;
                elsif IPIPE.D(8 downto 6) = "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= MOVEA;
                elsif IPIPE.D(8 downto 6) /= "001" and IPIPE.D(8 downto 6) /= "111" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                    OP_I <= MOVE;
                elsif IPIPE.D(8 downto 6) /= "001" and IPIPE.D(8 downto 6) /= "111" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= MOVE;
                end if;
            when x"4" => -- Miscellaneous.
                if IPIPE.D(11 downto 0) = x"E70" then
                    OP_I <= RESET;
                elsif IPIPE.D(11 downto 0) = x"E71" then
                    OP_I <= NOP;
                elsif IPIPE.D(11 downto 0) = x"E72" then
                    OP_I <= STOP;
                elsif IPIPE.D(11 downto 0) = x"E73" then
                    OP_I <= RTE;
                elsif IPIPE.D(11 downto 0) = x"E74" then
                    OP_I <= RTD;
                elsif IPIPE.D(11 downto 0) = x"E75" then
                    OP_I <= RTS;
                elsif IPIPE.D(11 downto 0) = x"E76" then
                    OP_I <= TRAPV;
                elsif IPIPE.D(11 downto 0) = x"E77" then
                    OP_I <= RTR;
                elsif IPIPE.D(11 downto 0) = x"AFC" then
                    OP_I <= ILLEGAL;
                elsif IPIPE.D(11 downto 1) = "11100111101" and IPIPE.C(11 downto 0) = x"000" then
                    OP_I <= MOVEC;
                elsif IPIPE.D(11 downto 1) = "11100111101" and IPIPE.C(11 downto 0) = x"001" then
                    OP_I <= MOVEC;
                elsif IPIPE.D(11 downto 1) = "11100111101" and IPIPE.C(11 downto 0) = x"002" then
                    OP_I <= MOVEC;
                elsif IPIPE.D(11 downto 1) = "11100111101" and IPIPE.C(11 downto 0) = x"800" then
                    OP_I <= MOVEC;
                elsif IPIPE.D(11 downto 1) = "11100111101" and IPIPE.C(11 downto 0) = x"801" then
                    OP_I <= MOVEC;
                elsif IPIPE.D(11 downto 1) = "11100111101" and IPIPE.C(11 downto 0) = x"802" then
                    OP_I <= MOVEC;
                elsif IPIPE.D(11 downto 1) = "11100111101" and IPIPE.C(11 downto 0) = x"803" then
                    OP_I <= MOVEC;
                elsif IPIPE.D(11 downto 1) = "11100111101" and IPIPE.C(11 downto 0) = x"804" then
                    OP_I <= MOVEC;
                elsif IPIPE.D(11 downto 1) = "11100111101" and IPIPE.C(11 downto 0) = x"805" then
                    OP_I <= MOVEC;
                elsif IPIPE.D(11 downto 1) = "11100111101" then
                    OP_I <= ILLEGAL; -- Not valid MOVEC patterns.
                elsif IPIPE.D(11 downto 3) = "100001001" then -- 68K20, 68K30, 68K40
                    OP_I <= BKPT;
                elsif IPIPE.D(11 downto 3) = "100000001" then -- 68K20, 68K30, 68K40
                    OP_I <= LINK; -- LONG.
                elsif IPIPE.D(11 downto 3) = "111001010" then
                    OP_I <= LINK; -- WORD.
                elsif IPIPE.D(11 downto 3) = "111001011" then
                    OP_I <= UNLK;
                elsif IPIPE.D(11 downto 3) = "100001000" then
                    OP_I <= SWAP;
                elsif IPIPE.D(11 downto 4) = x"E4" then
                    OP_I <= TRAP;
                elsif IPIPE.D(11 downto 4) = x"E6" then
                    OP_I <= MOVE_USP;
                else
                    case IPIPE.D(5 downto 3) is -- Addressing mode.
                        when "000" | "010" | "011" | "100" | "101" | "110" =>
                            if IPIPE.D(11 downto 6) = "110001" then
                                if IPIPE.C(11) = '1' then
                                    OP_I <= DIVS; -- Long.
                                else
                                    OP_I <= DIVU; -- Long.
                                end if;
                            elsif IPIPE.D(11 downto 6) = "001011" then
                                OP_I <= MOVE_FROM_CCR;
                            elsif IPIPE.D(11 downto 6) = "000011" then
                                OP_I <= MOVE_FROM_SR;
                            elsif IPIPE.D(11 downto 6) = "010011" then
                                OP_I <= MOVE_TO_CCR;                    
                            elsif IPIPE.D(11 downto 6) = "011011" then
                                OP_I <= MOVE_TO_SR;
                            elsif IPIPE.D(11 downto 6) = "110000" then
                                if IPIPE.C(11) = '1' then
                                    OP_I <= MULS; -- Long.
                                else
                                    OP_I <= MULU; -- Long.
                                end if;
                            elsif IPIPE.D(11 downto 6) = "100000" then
                                OP_I <= NBCD;
                            elsif IPIPE.D(11 downto 6) = "101011" then
                                OP_I <= TAS;
                            end if;
                        when  "111" => -- Not all registers are valid for this mode.
                            if IPIPE.D(11 downto 6) = "110001" and IPIPE.D(2 downto 0) < "101" then
                                if IPIPE.C(11) = '1' then
                                    OP_I <= DIVS; -- Long.
                                else
                                    OP_I <= DIVU; -- Long.
                                end if;
                            elsif IPIPE.D(11 downto 6) = "001011" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= MOVE_FROM_CCR;
                            elsif IPIPE.D(11 downto 6) = "000011" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= MOVE_FROM_SR;
                            elsif IPIPE.D(11 downto 6) = "010011" and IPIPE.D(2 downto 0) < "101" then
                                OP_I <= MOVE_TO_CCR;                    
                            elsif IPIPE.D(11 downto 6) = "011011" and IPIPE.D(2 downto 0) < "101" then
                                OP_I <= MOVE_TO_SR;
                            elsif IPIPE.D(11 downto 6) = "110000" and IPIPE.D(2 downto 0) < "101" then
                                if IPIPE.C(11) = '1' then
                                    OP_I <= MULS; -- Long.
                                else
                                    OP_I <= MULU; -- Long.
                                end if;
                            elsif IPIPE.D(11 downto 6) = "100000" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= NBCD;
                            elsif IPIPE.D(11 downto 6) = "101011" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= TAS;
                            end if;
                        when others =>
                            null;
                    end case;
                                
                    case IPIPE.D(5 downto 3) is -- Addressing mode.
                        when "010" | "101" | "110" =>
                            if IPIPE.D(11 downto 6) = "100001" then
                                OP_I <= PEA;
                            elsif IPIPE.D(11 downto 6) = "111010" then
                                OP_I <= JSR;
                            elsif IPIPE.D(11 downto 6) = "111011" then
                                OP_I <= JMP;
                            end if;
                        when  "111" => -- Not all registers are valid for this mode.
                            if IPIPE.D(11 downto 6) = "100001" and IPIPE.D(2 downto 0) < "100" then
                                OP_I <= PEA;
                            elsif IPIPE.D(11 downto 6) = "111010" and IPIPE.D(2 downto 0) < "100" then
                                OP_I <= JSR;
                            elsif IPIPE.D(11 downto 6) = "111011" and IPIPE.D(2 downto 0) < "100" then
                                OP_I <= JMP;
                            end if;
                        when others =>
                            null;
                    end case;

                    -- For the following operation codes a SIZE (IPIPE.D(7 downto 6)) is not valid.
                    -- For the following operation codes an addressing mode x"001" is not valid.
                    if IPIPE.D(7 downto 6) < "11" and IPIPE.D(5 downto 3) /= "001" and IPIPE.D(5 downto 3) /= "111" then
                        case IPIPE.D(11 downto 8) is
                            when x"0" => OP_I <= NEGX;
                            when x"2" => OP_I <= CLR;
                            when x"4" => OP_I <= NEG;
                            when x"6" => OP_I <= NOT_B;
                            when others => null;
                        end case;
                    -- Not all registers are valid for the addressing mode "111":
                    elsif IPIPE.D(7 downto 6) < "11" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                        case IPIPE.D(11 downto 8) is
                            when x"0" => OP_I <= NEGX;
                            when x"2" => OP_I <= CLR;
                            when x"4" => OP_I <= NEG;
                            when x"6" => OP_I <= NOT_B;
                            when others => null;
                        end case;
                    end if;

                    -- if IPIPE.D(11 downto 8) = x"A" and IPIPE.D(7 downto 6) < "11" and IPIPE.D(5 downto 3) = "111" and (IPIPE.D(2 downto 0) < "010" or IPIPE.D(2 downto 0) = "100") then -- 68K
                    if IPIPE.D(11 downto 8) = x"A" and IPIPE.D(7 downto 6) < "11" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                        case IPIPE.D(7 downto 6) is
                            when "01" | "10" => OP_I <= TST; -- Long or word, all addressing modes.
                            when others => -- Byte: Address register direct not allowed.
                                if IPIPE.D(2 downto 0) /= "100" then
                                    OP_I <= TST;
                                end if;
                        end case;
                    elsif IPIPE.D(11 downto 8) = x"A" and IPIPE.D(7 downto 6) < "11" and IPIPE.D(5 downto 3) /= "111" then
                        case IPIPE.D(7 downto 6) is
                            when "01" | "10" => OP_I <= TST; -- Long or word, all addressing modes.
                            when others => -- Byte: Address register direct not allowed.
                                if IPIPE.D(5 downto 3) /= "001" then
                                    OP_I <= TST;
                                end if;
                        end case;
                    end if;

                    if IPIPE.D(11 downto 9) = "100" and IPIPE.D(5 downto 3) = "000" then
                        case IPIPE.D(8 downto 6) is -- Valid OPMODES for this operation code.
                            when "010" | "011" => OP_I <= EXT;
                            when "111" => OP_I <= EXTB;
                            when others => null;
                        end case;
                    end if;
                    
                    if IPIPE.D(8 downto 6) = "111" then
                        case IPIPE.D(5 downto 3) is -- OPMODES.
                            when "010" | "101" | "110" =>
                                OP_I <= LEA;
                            when "111" =>
                                if IPIPE.D(2 downto 0) < "100" then -- Not all registers are valid for this OPMODE.
                                    OP_I <= LEA;
                                end if;
                            when others => null;
                        end case;
                    end if;

                    if IPIPE.D(11) = '1' and IPIPE.D(9 downto 7) = "001" then
                        if IPIPE.D(10) = '0' then -- Register to memory transfer.
                            case IPIPE.D(5 downto 3) is -- OPMODES, no postincrement addressing.
                                when "010" | "100" | "101" | "110" =>
                                    OP_I <= MOVEM;
                                when "111" =>
                                    if IPIPE.D(2 downto 0) = "000" or IPIPE.D(2 downto 0) = "001" then
                                        OP_I <= MOVEM;
                                    end if;
                                when others => null;
                            end case;
                        else -- Memory to register transfer, no predecrement addressing.
                            case IPIPE.D(5 downto 3) is -- OPMODES.
                                when "010" | "011" | "101" | "110" =>
                                    OP_I <= MOVEM;
                                when "111" =>
                                    if IPIPE.D(2 downto 0) < "100" then
                                        OP_I <= MOVEM;
                                    end if;
                                when others => null;
                            end case;
                        end if;
                    end if;

                    -- The size must be "10" or "11" and the OPMODE may not be "001".
                    if IPIPE.D(8 downto 7) >= "10" and IPIPE.D(6 downto 3) = x"7" and IPIPE.D(2 downto 0) < "101" then
                        OP_I <= CHK;
                    elsif IPIPE.D(8 downto 7) >= "10" and IPIPE.D(6 downto 3) /= x"1" and IPIPE.D(6 downto 3) < x"7" then
                        OP_I <= CHK;
                    end if;
                end if;
            when x"5" => -- ADDQ / SUBQ / Scc / DBcc / TRAPcc.
                if IPIPE.D(7 downto 3) = "11001" then
                    OP_I <= DBcc;
                elsif IPIPE.D(7 downto 6) = "11" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= Scc;
                elsif IPIPE.D(7 downto 6) = "11" and IPIPE.D(5 downto 3) /= "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= Scc;
                --
                elsif IPIPE.D(8) = '0' and IPIPE.D(7 downto 6) < "11" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= ADDQ;
                elsif IPIPE.D(8) = '0' and (IPIPE.D(7 downto 6) = "01" or IPIPE.D(7 downto 6) = "10") and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= ADDQ;
                elsif IPIPE.D(8) = '0' and IPIPE.D(7 downto 6) = "00" and IPIPE.D(5 downto 3) /= "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= ADDQ;
                --
                elsif IPIPE.D(8) = '1' and IPIPE.D(7 downto 6) < "11" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= SUBQ;
                elsif IPIPE.D(8) = '1' and (IPIPE.D(7 downto 6) = "01" or IPIPE.D(7 downto 6) = "10") and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= SUBQ;
                elsif IPIPE.D(8) = '1' and IPIPE.D(7 downto 6) = "00" and IPIPE.D(5 downto 3) /= "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= SUBQ;
                --
                elsif IPIPE.D(7 downto 3) = "11111" then
                    OP_I <= TRAPcc;
                end if;
            when x"6" => -- Bcc / BSR / BRA.
                if IPIPE.D(11 downto 8) = x"0" then
                    OP_I <= BRA;
                elsif IPIPE.D(11 downto 8) = x"1" then
                    OP_I <= BSR;
                else
                    OP_I <= Bcc;
                end if;
            when x"7" => -- MOVEQ.
                if IPIPE.D(8) = '0' then
                    OP_I <= MOVEQ;
                end if;
            when x"8" => -- OR / DIV / SBCD / PACK / UNPK.
                if IPIPE.D(8 downto 4) = "10100" then
                    OP_I <= PACK;
                elsif IPIPE.D(8 downto 4) = "11000" then
                    OP_I <= UNPK;
                elsif IPIPE.D(8 downto 6) = "011" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                    OP_I <= DIVU; -- WORD.
                elsif IPIPE.D(8 downto 6) = "011" and IPIPE.D(5 downto 3) /= "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= DIVU; -- WORD.
                elsif IPIPE.D(8 downto 6) = "111" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                    OP_I <= DIVS; -- WORD.
                elsif IPIPE.D(8 downto 6) = "111" and IPIPE.D(5 downto 3) /= "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= DIVS; -- WORD.
                elsif IPIPE.D(8 downto 4) = "10000" then
                    OP_I <= SBCD;
                end if;
                --
                case IPIPE.D(8 downto 6) is
                    when "000" | "001" | "010" =>
                        if IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                            OP_I <= OR_B;
                        elsif IPIPE.D(5 downto 3) /= "001" and IPIPE.D(5 downto 3) /= "111" then
                            OP_I <= OR_B;
                        end if;
                    when "100" | "101" | "110" =>
                        if IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                            OP_I <= OR_B;
                        elsif IPIPE.D(5 downto 3) > "001" and IPIPE.D(5 downto 3) /= "111" then
                            OP_I <= OR_B;
                        end if;
                    when others =>
                        null;
                end case;
            when x"9" => -- SUB / SUBX.
                case IPIPE.D(8 downto 6) is
                    when "000" => -- Byte size.
                        if IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                            OP_I <= SUB;
                        elsif IPIPE.D(5 downto 3) /= "111" and IPIPE.D(5 downto 3) /= "001" then
                            OP_I <= SUB;
                        end if;
                    when "001" | "010" => -- Word and long.
                        if IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                            OP_I <= SUB;
                        elsif IPIPE.D(5 downto 3) /= "111" then
                            OP_I <= SUB;
                        end if;
                    when "100" =>
                        if IPIPE.D(5 downto 3) = "000" or IPIPE.D(5 downto 3) = "001" then
                            OP_I <= SUBX;
                        elsif IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                            OP_I <= SUB;
                        elsif IPIPE.D(5 downto 3) /= "111" and IPIPE.D(5 downto 3) /= "001" then  -- Byte size.
                            OP_I <= SUB;
                        end if;
                    when "101" | "110"  =>
                        if IPIPE.D(5 downto 3) = "000" or IPIPE.D(5 downto 3) = "001" then
                            OP_I <= SUBX;
                        elsif IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                            OP_I <= SUB;
                        elsif IPIPE.D(5 downto 3) /= "111" then -- Word and long.
                            OP_I <= SUB;
                        end if;
                    when "011" | "111" =>
                        if IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                            OP_I <= SUBA;
                        elsif IPIPE.D(5 downto 3) /= "111" then
                            OP_I <= SUBA;
                        end if;
                    when others => -- U, X, Z, W, H, L, -.
                        null;
                end case;
            when x"A" => -- (1010, Unassigned, Reserved).
                OP_I <= UNIMPLEMENTED;
            when x"B" => -- CMP / EOR.
                if IPIPE.D(8) = '1' and IPIPE.D(7 downto 6) < "11" and IPIPE.D(5 downto 3) = "001" then
                    OP_I <= CMPM;
                else
                    case IPIPE.D(8 downto 6) is -- OPMODE field.
                        when "000" =>
                            if IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                                OP_I <= CMP;
                            elsif IPIPE.D(5 downto 3) /= "001" and IPIPE.D(5 downto 3) /= "111" then
                                OP_I <= CMP;
                            end if;
                        when "001" | "010" =>
                            if IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                                OP_I <= CMP;
                            elsif IPIPE.D(5 downto 3) /= "111" then
                                OP_I <= CMP;
                            end if;
                        when "011" | "111" =>
                            if IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                                OP_I <= CMPA;
                            elsif IPIPE.D(5 downto 3) /= "111" then
                                OP_I <= CMPA;
                            end if;
                        when "100" | "101" | "110" =>
                            if IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                                OP_I <= EOR;
                            elsif IPIPE.D(5 downto 3) /= "001" and IPIPE.D(5 downto 3) /= "111" then
                                OP_I <= EOR;
                            end if;
                        when others => -- U, X, Z, W, H, L, -.
                            null;
                    end case;
                end if;
            when x"C" => -- AND / MUL / ABCD / EXG.
                if IPIPE.D(8 downto 4) = "10000" then
                    OP_I <= ABCD;
                elsif IPIPE.D(8 downto 6) = "011" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                    OP_I <= MULU; -- WORD.
                elsif IPIPE.D(8 downto 6) = "011" and IPIPE.D(5 downto 3) /= "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= MULU; -- WORD.
                elsif IPIPE.D(8 downto 6) = "111" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                    OP_I <= MULS; -- WORD.
                elsif IPIPE.D(8 downto 6) = "111" and IPIPE.D(5 downto 3) /= "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= MULS; -- WORD.
                elsif IPIPE.D(8 downto 3) = "101000" or IPIPE.D(8 downto 3) = "101001" or IPIPE.D(8 downto 3) = "110001" then
                    OP_I <= EXG;
                else
                    case IPIPE.D(8 downto 6) is -- OPMODE
                        when "000" | "001" | "010" =>
                            if IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                                OP_I <= AND_B;
                            elsif IPIPE.D(5 downto 3) /= "001" and IPIPE.D(5 downto 3) /= "111" then
                                OP_I <= AND_B;
                            end if;
                        when "100" | "101" | "110" =>
                            if IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                                OP_I <= AND_B;
                            elsif IPIPE.D(5 downto 3) > "001" and IPIPE.D(5 downto 3) /= "111" then
                                OP_I <= AND_B;
                            end if;
                        when others =>
                            null;
                    end case;
                end if;
            when x"D" => -- ADD / ADDX.
                case IPIPE.D(8 downto 6) is
                    when "000" =>
                        if IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                            OP_I <= ADD;
                        elsif IPIPE.D(5 downto 3) /= "111" and IPIPE.D(5 downto 3) /= "001" then
                            OP_I <= ADD;
                        end if;
                    when "001" | "010" =>
                        if IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                            OP_I <= ADD;
                        elsif IPIPE.D(5 downto 3) /= "111" then
                            OP_I <= ADD;
                        end if;
                    when "100"  =>
                        if IPIPE.D(5 downto 3) = "000" or IPIPE.D(5 downto 3) = "001" then
                            OP_I <= ADDX;
                        elsif IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                            OP_I <= ADD;
                        elsif IPIPE.D(5 downto 3) /= "111" and IPIPE.D(5 downto 3) /= "001" then
                            OP_I <= ADD;
                        end if;
                    when "101" | "110"  =>
                        if IPIPE.D(5 downto 3) = "000" or IPIPE.D(5 downto 3) = "001" then
                            OP_I <= ADDX;
                        elsif IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                            OP_I <= ADD;
                        elsif IPIPE.D(5 downto 3) /= "111" then
                            OP_I <= ADD;
                        end if;
                    when "011" | "111" =>
                        if IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "101" then
                            OP_I <= ADDA;
                        elsif IPIPE.D(5 downto 3) /= "111" then
                            OP_I <= ADDA;
                        end if;
                    when others => -- U, X, Z, W, H, L, -.
                        null;
                end case;
            when x"E" => -- Shift / Rotate / Bit Field.
                if IPIPE.D(11 downto 6) = "101011" and (IPIPE.D(5 downto 3) = "000" or IPIPE.D(5 downto 3) = "010") then
                    OP_I <= BFCHG;
                elsif IPIPE.D(11 downto 6) = "101011" and (IPIPE.D(5 downto 3) >= "101" or IPIPE.D(5 downto 3) <= "110") then
                    OP_I <= BFCHG;
                elsif IPIPE.D(11 downto 6) = "101011" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= BFCHG;
                elsif IPIPE.D(11 downto 6) = "110011" and (IPIPE.D(5 downto 3) = "000" or IPIPE.D(5 downto 3) = "010") then
                    OP_I <= BFCLR;
                elsif IPIPE.D(11 downto 6) = "110011" and (IPIPE.D(5 downto 3) >= "101" or IPIPE.D(5 downto 3) <= "110") then
                    OP_I <= BFCLR;
                elsif IPIPE.D(11 downto 6) = "110011" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= BFCLR;
                elsif IPIPE.D(11 downto 6) = "101111" and (IPIPE.D(5 downto 3) = "000" or IPIPE.D(5 downto 3) = "010") then
                    OP_I <= BFEXTS;
                elsif IPIPE.D(11 downto 6) = "101111" and (IPIPE.D(5 downto 3) >= "101" or IPIPE.D(5 downto 3) <= "110") then
                    OP_I <= BFEXTS;
                elsif IPIPE.D(11 downto 6) = "101111" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "100" then
                    OP_I <= BFEXTS;
                elsif IPIPE.D(11 downto 6) = "100111" and (IPIPE.D(5 downto 3) = "000" or IPIPE.D(5 downto 3) = "010") then
                    OP_I <= BFEXTU;
                elsif IPIPE.D(11 downto 6) = "100111" and (IPIPE.D(5 downto 3) >= "101" or IPIPE.D(5 downto 3) <= "110") then
                    OP_I <= BFEXTU;
                elsif IPIPE.D(11 downto 6) = "100111" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "100" then
                    OP_I <= BFEXTU;
                elsif IPIPE.D(11 downto 6) = "110111" and (IPIPE.D(5 downto 3) = "000" or IPIPE.D(5 downto 3) = "010") then
                    OP_I <= BFFFO;
                elsif IPIPE.D(11 downto 6) = "110111" and (IPIPE.D(5 downto 3) >= "101" or IPIPE.D(5 downto 3) <= "110") then
                    OP_I <= BFFFO;
                elsif IPIPE.D(11 downto 6) = "110111" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "100" then
                    OP_I <= BFFFO;
                elsif IPIPE.D(11 downto 6) = "111111" and (IPIPE.D(5 downto 3) = "000" or IPIPE.D(5 downto 3) = "010") then
                    OP_I <= BFINS;
                elsif IPIPE.D(11 downto 6) = "111111" and (IPIPE.D(5 downto 3) >= "101" or IPIPE.D(5 downto 3) <= "110") then
                    OP_I <= BFINS;
                elsif IPIPE.D(11 downto 6) = "111111" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= BFINS;
                elsif IPIPE.D(11 downto 6) = "111011" and (IPIPE.D(5 downto 3) = "000" or IPIPE.D(5 downto 3) = "010") then
                    OP_I <= BFSET;
                elsif IPIPE.D(11 downto 6) = "111011" and (IPIPE.D(5 downto 3) >= "101" or IPIPE.D(5 downto 3) <= "110") then
                    OP_I <= BFSET;
                elsif IPIPE.D(11 downto 6) = "111011" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= BFSET;
                elsif IPIPE.D(11 downto 6) = "100011" and (IPIPE.D(5 downto 3) = "000" or IPIPE.D(5 downto 3) = "010") then
                    OP_I <= BFTST;
                elsif IPIPE.D(11 downto 6) = "100011" and (IPIPE.D(5 downto 3) >= "101" or IPIPE.D(5 downto 3) <= "110") then
                    OP_I <= BFTST;
                elsif IPIPE.D(11 downto 6) = "100011" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "100" then
                    OP_I <= BFTST;
                elsif IPIPE.D(11 downto 6) = "000011" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= ASR; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "000011" and IPIPE.D(5 downto 3) > "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= ASR; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "000111" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= ASL; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "000111" and IPIPE.D(5 downto 3) > "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= ASL; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "001011" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= LSR; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "001011" and IPIPE.D(5 downto 3) > "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= LSR; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "001111" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= LSL; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "001111" and IPIPE.D(5 downto 3) > "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= LSL; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "010011" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= ROXR; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "010011" and IPIPE.D(5 downto 3) > "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= ROXR; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "010111" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= ROXL; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "010111" and IPIPE.D(5 downto 3) > "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= ROXL; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "011011" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= ROTR; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "011011" and IPIPE.D(5 downto 3) > "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= ROTR; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "011111" and IPIPE.D(5 downto 3) = "111" and IPIPE.D(2 downto 0) < "010" then
                    OP_I <= ROTL; -- Memory shifts.
                elsif IPIPE.D(11 downto 6) = "011111" and IPIPE.D(5 downto 3) > "001" and IPIPE.D(5 downto 3) /= "111" then
                    OP_I <= ROTL; -- Memory shifts.
                elsif IPIPE.D(8) = '0' and IPIPE.D(7 downto 6) < "11" and IPIPE.D(4 downto 3) = "00" then
                    OP_I <= ASR; -- Register shifts.
                elsif IPIPE.D(8) = '1' and IPIPE.D(7 downto 6) < "11" and IPIPE.D(4 downto 3) = "00" then
                    OP_I <= ASL; -- Register shifts.
                elsif IPIPE.D(8) = '0' and IPIPE.D(7 downto 6) < "11" and IPIPE.D(4 downto 3) = "01" then
                    OP_I <= LSR; -- Register shifts.
                elsif IPIPE.D(8) = '1' and IPIPE.D(7 downto 6) < "11" and IPIPE.D(4 downto 3) = "01" then
                    OP_I <= LSL; -- Register shifts.
                elsif IPIPE.D(8) = '0' and IPIPE.D(7 downto 6) < "11" and IPIPE.D(4 downto 3) = "10" then
                    OP_I <= ROXR; -- Register shifts.
                elsif IPIPE.D(8) = '1' and IPIPE.D(7 downto 6) < "11" and IPIPE.D(4 downto 3) = "10" then
                    OP_I <= ROXL; -- Register shifts.
                elsif IPIPE.D(8) = '0' and IPIPE.D(7 downto 6) < "11" and IPIPE.D(4 downto 3) = "11" then
                    OP_I <= ROTR; -- Register shifts.
                elsif IPIPE.D(8) = '1' and IPIPE.D(7 downto 6) < "11" and IPIPE.D(4 downto 3) = "11" then
                    OP_I <= ROTL; -- Register shifts.
                end if;
            when x"F" => -- 1111, Coprocessor Interface / 68K40 Extensions.
                OP_I <= UNIMPLEMENTED;
            when others => -- U, X, Z, W, H, L, -.
                null;
            end case;
    end process OP_DECODE;
end BEHAVIOR;
