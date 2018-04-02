library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_tb is
end entity hdmi_tb;

architecture sim of hdmi_tb is
    signal clk_50               : std_logic := '0';
    signal reset_n              : std_logic := '0';

    signal clk_1536k,
           plls_locked          : std_logic := '0';

	-- jtag uart signals
	signal rx_data,
		   tx_data			    : std_logic_vector(7 downto 0);
	signal rx_busy,
		   tx_busy			    : std_logic;
	signal tx_start			    : std_logic;

    
    -- HDMI signals
    signal hdmi_i2c_scl         : std_logic := '0';
    signal hdmi_i2c_sda         : std_logic := '0';
    signal hdmi_i2s             : std_logic_vector(3 downto 0);
    signal hdmi_lrclk           : std_logic;
    signal hdmi_mclk            : std_logic;
    signal hdmi_sclk            : std_logic;
    signal hdmi_tx_clk          : std_logic;
    signal hdmi_tx_d            : std_logic_vector(23 downto 0);
    signal hdmi_tx_de           : std_logic;
    signal hdmi_tx_hs           : std_logic;
    signal hdmi_tx_int          : std_logic;
    signal hdmi_tx_vs           : std_logic;

    signal reset_button_n       : std_logic := '1';

    signal sda_counter          : integer range 0 to 8 := 0;

    signal i2c_read_req,
           i2c_read_response_valid  : std_logic;
    signal i2c_read_response,
           i2c_write_data       : std_logic_vector(7 downto 0);
    
begin
    hdmi_i2c_scl <= 'H';
    hdmi_i2c_sda <= 'H';                                -- add pull-ups to i2c signals

    i_i2c_slave : entity work.i2c_slave
        generic map
        (
            SLAVE_ADDR          => 7x"39"
        )
        port map
        (
            clk                 => clk_50,
            reset_n             => reset_n,

            scl                 => hdmi_i2c_scl,
            sda                 => hdmi_i2c_sda,

            -- user interface
            read_req            => i2c_read_req,
            data_to_master      => i2c_read_response,
            data_valid          => i2c_read_response_valid,
            data_from_master    => i2c_write_data
        );

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
        generic map
        (
            CLK_FREQUENCY       => 50_000_000,
            I2C_FREQUENCY       => 2_000_000        -- only for simulation; real device supports 400 KHz!
        )
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
            hdmi_tx_vs          => hdmi_tx_vs,
            reset_button_n      => reset_button_n
        );


    i_deca_clocks : entity work.deca_clocks
        port map
        (
            clk                 => clk_50,
            reset_n             => reset_n,

            -- clocks
            clk_1536k           => clk_1536k,
            
            locked              => plls_locked
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
