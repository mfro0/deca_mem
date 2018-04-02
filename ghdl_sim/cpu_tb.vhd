library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu_tb is
end entity cpu_tb;

architecture sim of cpu_tb is
    signal clk_50               : std_logic := '0';
    signal reset_n              : std_logic := '0';

    signal plls_locked          : std_logic := '0';

	-- jtag uart signals
	signal rx_data,
		   tx_data			    : std_logic_vector(7 downto 0);
	signal rx_busy,
		   tx_busy			    : std_logic;
	signal tx_start			    : std_logic;

    
    signal reset_button_n       : std_logic := '1';

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
            clk                 => clk_50,
            reset_n             => reset_n
        );

    -- add our jtag uart
    i_jtag_uart : entity work.jtag_uart
        port map
        (
            clk				    => clk_50,
            reset_n             => reset_n,
            rx_data			    => rx_data,
            rx_busy			    => rx_busy,
            tx_data			    => tx_data,
            tx_busy			    => tx_busy,
            tx_start		    => tx_start
        );
end architecture sim;
