library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu_tb is
end entity cpu_tb;

architecture sim of cpu_tb is
    signal clk_50                   : std_logic := '0';
    signal reset_n                  : std_logic := '0';

    signal plls_locked              : std_logic := '0';

	-- jtag uart signals
	signal rx_data,
		   tx_data                  : std_logic_vector(7 downto 0);
	signal rx_data_ready,
		   tx_busy			        : std_logic;
	signal tx_start			        : std_logic;


    signal reset_button_n           : std_logic := '1';

    signal uart_out_ready           : std_logic;

    signal uart_in_data_available   : std_logic;
    signal uart_in_data             : std_logic_vector(7 downto 0);

    constant hello_world_string     : string := "Hello World!";

begin
    -- reset
    p_initial : process
    begin
        reset_n <= '0';
        wait for 1000 ns;
        reset_n <= '1';
        wait;
    end process p_initial;

    -- feed the 50 MHz main clock
    p_clk_50 : process
    begin
        wait for 20 ns / 2;
        clk_50 <= not clk_50;
    end process p_clk_50;

    -- the m68k CPU
    i_cpu : entity work.simple_m68k
        port map
        (
            clk                     => clk_50,
            reset_n                 => reset_n,

            uart_out_ready          => uart_out_ready,
            uart_in_data_available  => uart_in_data_available,
            uart_in_data            => uart_in_data
        );

    -- add our jtag uart
    i_jtag_uart : entity work.jtag_uart
        port map
        (
            clk				    => clk_50,
            reset_n             => reset_n,

            rx_data			    => rx_data,
            rx_data_ready       => rx_data_ready,
            tx_data			    => tx_data,
            tx_busy			    => tx_busy,
            tx_start		    => tx_start
        );

    uart_out : process(all)
        variable str_index      : integer := hello_world_string'low;
        variable c              : character;
    begin
        if not reset_n then
            str_index := hello_world_string'low;
            tx_start <= '0';
        elsif rising_edge(clk_50) then
            if not tx_busy then
                if str_index <= hello_world_string'high then
                    c := hello_world_string(str_index);
                    tx_data <= std_logic_vector(to_unsigned(character'pos(c), 8));
                    tx_start <= '1';
                    str_index := str_index + 1;
                else
                    str_index := hello_world_string'low;
                end if;
            else
                tx_start <= '0';
            end if;
        end if;
    end process uart_out;
end architecture sim;
