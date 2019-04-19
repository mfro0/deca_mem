library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_hdmi_config is
    generic
    (
        CLK_FREQUENCY       : integer;
        I2C_FREQUENCY       : integer
    );
    port
    (
        clk                 : in std_ulogic;
        reset_n             : in std_ulogic;
        
        i2c_sclk            : inout std_logic;
        i2c_sdat            : inout std_logic;
        hdmi_tx_int         : in std_ulogic;
        
        -- debug
        ack_error           : out std_ulogic;
        i2c_busy            : out std_ulogic;
        verify_start        : in std_ulogic;
        reset_button_n      : in std_ulogic
    );
end entity i2c_hdmi_config;

architecture rtl of i2c_hdmi_config is
    signal i2c_ena,
           v_i2c_ena        : std_ulogic := '0';
    signal i2c_addr,
           v_i2c_addr       : std_ulogic_vector(6 downto 0);
    signal i2c_rw,
           v_i2c_rw         : std_ulogic := '0';
    signal i2c_data_rd      : std_ulogic_vector(7 downto 0);
    signal i2c_data_wr,
           v_i2c_data_wr    : std_ulogic_vector(7 downto 0);
    signal i2c_ack_err      : std_ulogic := '0';

    signal index            : natural;

    -- ADV7513 DDC controller initialisation
    type register_type is record
        reg                 : std_ulogic_vector(7 downto 0);
        val                 : std_ulogic_vector(7 downto 0);
    end record;
    
    type config_data_type is array(natural range <>) of register_type;
    constant config_data       : config_data_type :=
    (
        ( x"98", x"03" ),           -- must be set to 0x03 for proper operation
        ( x"01", x"00" ),           -- set 'n' value at 6144
        ( x"02", x"18" ),           -- set 'n' value at 6144
        ( x"03", x"00" ),           -- set 'n' value at 6144
        ( x"14", x"70" ),           -- set ch count in the channel status to 8
        ( x"15", x"20" ),           -- input 444 (RGB or YcrCb) with separate syncs, 48 kHz fs
        ( x"16", x"30" ),           -- output format 444, 24 bit input
        ( x"18", x"46" ),           -- disable CSC
        ( x"40", x"80" ),           -- general control packet enable
        ( x"41", x"10" ),           -- power down control
        ( x"49", x"a8" ),           -- set dither mode - 12-to-10 bit
        ( x"55", x"10" ),           -- set RGB in AVI infoframe
        ( x"56", x"08" ),           -- set active format aspect
        ( x"96", x"f6" ),           -- set interrupt
        ( x"73", x"07" ),           -- info frame ch count to 8
        ( x"76", x"1f" ),           -- set speaker allocation for 8 channels
        ( x"98", x"03" ),           -- must be set to 0x03 for proper operation
        ( x"99", x"02" ),           -- must be set to default value
        ( x"9a", x"e0" ),           -- must be set to 0b1110000
        ( x"9c", x"30" ),           -- PLL filter R1 value
        ( x"9d", x"61" ),           -- set clock divide
        ( x"a2", x"a4" ),           -- must be set to 0xa4 for proper operation
        ( x"a3", x"a4" ),           -- must be set to 0xa4 for proper operation
        ( x"a5", x"04" ),           -- must be set to default value
        ( x"ab", x"40" ),           -- must be set to default value
        ( x"af", x"16" ),           -- select HDMI mode
        ( x"ba", x"60" ),           -- no clock delay
        ( x"d1", x"ff" ),           -- must be set to default value
        ( x"de", x"10" ),           -- must be set to default value
        ( x"e4", x"60" ),           -- must be set to default value
        ( x"fa", x"7d" ),           -- number of times to look for good phase
        ( x"98", x"03" )
    );

    type config_setup_type is (STATE0, STATE1, STATE2, STATE3, STATE4);
    signal state                : config_setup_type := STATE0;
    signal configured           : std_ulogic := '0';
    signal my_reset_n           : std_logic;
begin
    my_reset_n <= reset_n and reset_button_n;
    
    p_i2c_send_data : process(all)
    begin
        if not my_reset_n then
            index <= config_data'low;
            state <= STATE0;
            i2c_ena <= '0';
        elsif rising_edge(clk) then
            if index <= config_data'high then
                case state is
                    when STATE0 =>
                        i2c_ena <= '1';
                        i2c_addr <= 7x"39";
                        i2c_rw <= '0';                      -- write
                        i2c_data_wr <= std_ulogic_vector(config_data(index).reg);
                        state <= STATE1;
                        
                     when STATE1 =>
                        -- wait until busy gets asserted
                        if i2c_busy then
                            state <= STATE2;
                        end if;
                    
                    when STATE2 =>
                        if not i2c_busy then
                            i2c_data_wr <= std_ulogic_vector(config_data(index).val);
                            index <= index + 1;
                            state <= STATE3;
                        end if;
                        
                    when STATE3 =>
                        -- wait again for busy
                        if i2c_busy then
                            state <= STATE4;
                            i2c_ena <= '0';                 -- last command this turn
                        end if;
                    
                    when STATE4 =>
                        if not i2c_busy then
                            state <= STATE0;
                        end if;
                end case;
            else
                i2c_ena <= '0';
                configured <= '1';
            end if;
        end if;
    end process p_i2c_send_data;
    
    ack_error <= i2c_ack_err;

    
    i2c_mux : block
        signal mi2c_ena         : std_ulogic;
        signal mi2c_addr        : std_ulogic_vector(6 downto 0);
        signal mi2c_rw          : std_ulogic;
        signal mi2c_data_wr     : std_ulogic_vector(7 downto 0);
        
    begin
        
        mi2c_ena <= i2c_ena when not configured else v_i2c_ena;
        mi2c_addr <= i2c_addr when not configured else v_i2c_addr;
        mi2c_rw <= i2c_rw when not configured else v_i2c_rw;
        mi2c_data_wr <= i2c_data_wr when not configured else v_i2c_data_wr;
        
        i_i2c_master : entity work.i2c_master
            generic map
            (
                CLK_FREQUENCY   => CLK_FREQUENCY,           --  input clock speed from user logic in Hz
                I2C_FREQUENCY   => I2C_FREQUENCY            --  speed the i2c bus (scl) will run at in Hz
            )
            port map
            (
                clk             => clk,
                reset_n         => my_reset_n,
                ena             => mi2c_ena,
                busy            => i2c_busy,
                addr            => mi2c_addr,
                rw              => mi2c_rw,
                data_wr         => mi2c_data_wr,
                data_rd         => i2c_data_rd,
                ack_error       => i2c_ack_err,
                sda             => i2c_sdat,
                scl             => i2c_sclk
            );
    end block i2c_mux;
    --
    -- verify i2c configuration
    -- read registers
    --
    
    i2c_verifier : block
        signal terminal_busy            : std_ulogic;
        signal i2c_read_data            : std_ulogic_vector(7 downto 0);
        signal i2c_read_data_valid      : std_ulogic;
        
        type config_verify_state_type is (S0, S1, S2, S3, S4, S5, S6);
        signal config_verify_state      : config_verify_state_type := S0;
        signal index                    : natural := 0;
        signal data                     : std_ulogic_vector(7 downto 0);
    begin
        p_verify_config : process(all)
        begin
            if not my_reset_n then
                null;
            elsif rising_edge(clk) then
                case config_verify_state is
                
                    when S0 =>
                        -- caller wants us to start verification process
                        if verify_start then
                            config_verify_state <= S1;
                        end if;
                        
                    when S1 =>
                        -- start reading i2c data
                        v_i2c_ena <= '1';
                        v_i2c_addr <= 7x"39";
                        v_i2c_rw <= '0';                      -- write
                        v_i2c_data_wr <= std_ulogic_vector(config_data(index).reg);
                        config_verify_state <= S2;
                    
                    when S2 =>
                        -- wait until i2c_busy becomes active
                        if i2c_busy then
                            config_verify_state <= S3;
                        end if;
                        
                    when S3 =>
                        -- wait until i2c_busy becomes inactive again (to read the data)
                        if not i2c_busy then
                            v_i2c_rw <= '1';                  -- read
                            data <= i2c_data_rd;
                            index <= index + 1;
                            config_verify_state <= S4;
                        end if;
                        
                    when S4 =>
                        if not terminal_busy then
                            i2c_read_data_valid <= '1';
                            config_verify_state <= S5;
                        end if;
                        
                    when S5 =>
                        if i2c_busy then
                            i2c_read_data_valid <= '0';
                            config_verify_state <= S6;
                        end if;
                        
                    when S6 =>
                        if not i2c_busy then
                            config_verify_state <= S0;
                        end if;
                        
                end case; -- config_verify_state
            end if;
        end process P_verify_config;
        i_uart : entity work.jtag_number_display
            generic map
            (
                VALUE_WIDTH         => i2c_read_data'length
            )
            port map
            (
                clk                 => clk,
                reset_n             => reset_n,
                
                busy                => terminal_busy,
                valid               => i2c_read_data_valid,
                val                 => i2c_read_data
            );
    end block i2c_verifier;
end architecture rtl;
