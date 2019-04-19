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
begin
end architecture rtl;

--------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity jtag_number_display is
    generic
    (
        VALUE_WIDTH                 : natural
    );
    port
    (
        signal clk                  : in std_ulogic;
        signal reset_n              : in std_ulogic;
        
        signal val                  : in std_ulogic_vector(VALUE_WIDTH - 1 downto 0);
        signal valid                : in std_ulogic;                                    -- val is valid, start output
        signal busy                 : out std_ulogic := '0'                             -- if not busy
    );
end entity jtag_number_display;

architecture rtl of jtag_number_display is
    signal uart_out_start           : std_ulogic := '0';
    signal uart_out_idle            : std_ulogic := '0';
    signal uart_out_data            : character;

    signal uart_in_data_available   : std_ulogic;
    signal uart_in_data_req         : std_ulogic;
    signal uart_in_data             : character;
    signal uart_in_paused           : std_ulogic;
    
    function to_hstring(value  : std_ulogic_vector) return string is
        constant RESULT_LENGTH  : natural := (value'length + 3) / 4;
        variable pad            : std_ulogic_vector(1 to result_length * 4 - value'length);
        variable padded_value   : std_ulogic_vector(1 to result_length * 4);
        variable result         : string(1 to result_length);
        variable quad           : std_ulogic_vector(1 to 4);
    begin
        if value (value'left) = 'Z' then
            pad := (others => 'Z');
        else
            pad := (others => '0');
        end if;
        padded_value := pad & value;
        for i in 1 to RESULT_LENGTH loop
            quad := To_X01Z(padded_value(4 * i - 3 to 4 * i));
            case quad is
                when x"0"   => result(i) := '0';
                when x"1"   => result(i) := '1';
                when x"2"   => result(i) := '2';
                when x"3"   => result(i) := '3';
                when x"4"   => result(i) := '4';
                when x"5"   => result(i) := '5';
                when x"6"   => result(i) := '6';
                when x"7"   => result(i) := '7';
                when x"8"   => result(i) := '8';
                when x"9"   => result(i) := '9';
                when x"A"   => result(i) := 'A';
                when x"B"   => result(i) := 'B';
                when x"C"   => result(i) := 'C';
                when x"D"   => result(i) := 'D';
                when x"E"   => result(i) := 'E';
                when x"F"   => result(i) := 'F';
                when "ZZZZ" => result(i) := 'Z';
                when others => result(i) := 'X';
            end case;
        end loop;
        return result;
    end function to_hstring;

    function to_hstring(value : natural) return string is
        constant WIDTH          : integer := integer(ceil(log2(real(value'high))));
        variable uns            : unsigned(WIDTH - 1 downto 0) := (others => '0');
    begin
        uns := to_unsigned(value, uns'length);
        return to_hstring(std_ulogic_vector(uns));
    end function to_hstring;
    
    function to_hstring(value : unsigned) return string is
    begin
        return to_hstring(std_ulogic_vector(value));
    end function to_hstring;
    
begin 
    terminal_out : block
        signal c                : character := '+';

        signal str              : string(1 to integer(ceil(log2(real(VALUE_WIDTH)))));
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
    
                            -- convert value to hex
                            str <= to_hstring(val) & character'val(10);
                            
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
                            index <= index + 1;
                        end if;
    
                    when SEND =>
                        -- wait for uart_out_idle to become active again
                        if uart_out_idle then
                            if index > str'high then
                                index <= str'low;
                                busy <= '0';
                                out_status <= IDLE;
                            else
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
