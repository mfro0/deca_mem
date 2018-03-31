library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_tb is
end entity hdmi_tb;

architecture sim of hdmi_tb is
    signal clk_50               : std_ulogic := '0';
    signal reset_n              : std_ulogic := '0';

    signal clk_100,
           clk_125,
           clk_150,
           clk_175,
           clk_200,
           plls_locked          : std_ulogic;

	-- jtag uart signals
	signal rx_data,
		   tx_data			    : std_ulogic_vector(7 downto 0);
	signal rx_busy,
		   tx_busy			    : std_ulogic;
	signal tx_start			    : std_ulogic;

    
    -- HDMI signals
    signal hdmi_i2c_scl         : std_logic;
    signal hdmi_i2c_sda         : std_logic;
    signal hdmi_i2s             : std_ulogic_vector(3 downto 0);
    signal hdmi_lrclk           : std_ulogic;
    signal hdmi_mclk            : std_ulogic;
    signal hdmi_sclk            : std_ulogic;
    signal hdmi_tx_clk          : std_ulogic;
    signal hdmi_tx_d            : std_ulogic_vector(23 downto 0);
    signal hdmi_tx_de           : std_ulogic;
    signal hdmi_tx_hs           : std_ulogic;
    signal hdmi_tx_int          : std_ulogic;
    signal hdmi_tx_vs           : std_ulogic;
    
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

    i_hdmi_tx : entity work.hdmi_tx
        port map
        (
            clk_50              => clk_50,
            reset_n             => reset_n,
            
            -- HDMI chip config
            hdmi_i2c_scl        => hdmi_i2c_scl,
            hdmi_i2c_sda        => hdmi_i2c_sda,

            -- HDMI inter-IC sound bus (i2s)
            hdmi_i2s            => hdmi_i2s,
            hdmi_lrclk          => hdmi_lrclk,
            hdmi_mclk           => hdmi_mclk,
            hdmi_sclk           => hdmi_sclk,

            -- HDMI video
            hdmi_tx_clk         => hdmi_tx_clk,
            hdmi_tx_d           => hdmi_tx_d,
            hdmi_tx_de          => hdmi_tx_de,
            hdmi_tx_hs          => hdmi_tx_hs,

            -- HDMI interrupt
            hdmi_tx_int         => hdmi_tx_int,
            hdmi_tx_vs          => hdmi_tx_vs
        );


    i_deca_clocks : entity work.deca_clocks
        port map
        (
            clk                 => clk_50,
            reset_n             => reset_n,

            -- clocks
            clk_100             => clk_100,
            clk_125             => clk_125,
            clk_150             => clk_150,
            clk_175             => clk_175,
            clk_200             => clk_200,
            
            locked              => plls_locked
        );


    -- add our jtag uart
    i_jtag_uart : entity work.jtag_uart
        port map
        (
            clk				    => clk_50,
            rx_data			    => rx_data,
            rx_busy			    => rx_busy,
            tx_data			    => tx_data,
            tx_busy			    => tx_busy,
            tx_start		    => tx_start
        );
end architecture sim;
