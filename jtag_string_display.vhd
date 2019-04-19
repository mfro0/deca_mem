library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity jtag_string_display is
    generic
    (
        STRING_WIDTH                : natural
    );
    port
    (
        signal clk                  : in std_ulogic;
        signal reset_n              : in std_ulogic;
        
        signal str                  : in string(1 to STRING_WIDTH); -- string to send
        signal valid                : in std_ulogic;                -- start output
        signal busy                 : out std_ulogic := '0'         -- when not busy
    );
end entity jtag_string_display;

architecture rtl of jtag_string_display is
    signal uart_out_start           : std_ulogic := '0';
    signal uart_out_idle            : std_ulogic := '0';
    signal uart_out_data            : character;

    signal uart_in_data_available   : std_ulogic;
    signal uart_in_data_req         : std_ulogic;
    signal uart_in_data             : character;
    signal uart_in_paused           : std_ulogic;
begin 
    terminal_out : block
        signal c                : character := '+';

        type out_status_type is (IDLE, START, REQ, SEND);
        signal out_status       : out_status_type := IDLE;

        signal str_out_start    : std_ulogic := '0';
        signal index            : integer := str'low;
    begin
        -- start string write if previous write string finished
        str_out_start <= '1' when busy = '0' and valid = '1' else '0';

        writestring : process(all)
        begin
            if not reset_n then
                null;
            elsif rising_edge(clk) then
                case out_status is
                    when IDLE =>
                        if str_out_start = '1' then                            
                            busy <= '1';
                            out_status <= START;
                        end if;
    
                    when START =>
                        if uart_out_idle then
                            uart_out_data <= str(index);
                            uart_out_start <= '1';
                            out_status <= REQ;
                        end if;
    
                    when REQ =>
                        -- wait for uart_out_idle to become inactive
                        if not uart_out_idle then
                            out_status <= SEND;
                            uart_out_start <= '0';
                        end if;
    
                    when SEND =>
                        -- wait for uart_out_idle to become active again
                        if uart_out_idle then
                            if index > str'high or str(index) = character'val(0) then
                                index <= str'low;
                                busy <= '0';
                                out_status <= IDLE;
                            else
                                index <= index + 1;
                                out_status <= START;
                            end if;
                        end if;
                end case;
            end if; -- if rising_edge(clk)
        end process writestring;
    end block terminal_out;

    i_uart : entity work.jtag_uart
        generic map
        (
            -- disable FIFO to make sure we detect overruns
            LOG2_RXFIFO_DEPTH   => 0,
            LOG2_TXFIFO_DEPTH   => 0
        )
        port map
        (
            clk                 => clk,
            reset_n             => reset_n,
            
            rx_data             => uart_in_data,
            rx_ready            => uart_in_data_available,
            rx_data_req         => uart_in_data_req,
            rx_paused           => uart_in_paused,
            
            tx_data             => uart_out_data,
            tx_start            => uart_out_start,
            tx_idle             => uart_out_idle
        );
end architecture rtl;

