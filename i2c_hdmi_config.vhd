library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_hdmi_config is
    generic
    (
        CLK_FREQ            : integer := 50000000;      -- 50 MHz
        I2C_FREQ            : integer := 20000;         -- 20 KHz
        LUT_SIZE            : integer := 31     
    );
    port
    (
        iclk                : in std_ulogic;
        irst_n              : in std_ulogic;
        i2c_sclk            : out std_ulogic;
        i2c_sdat            : inout std_logic;
        hdmi_tx_int         : in std_ulogic
    );
end entity i2c_hdmi_config;

architecture rtl of i2c_hdmi_config is
    signal mi2c_clk_div     : unsigned(15 downto 0);
    signal mi2c_data        : unsigned(23 downto 0);
    signal mi2c_ctrl_clk    : std_ulogic;
    signal mi2c_go          : std_ulogic;
    signal mi2c_end         : std_ulogic;
    signal mi2c_ack         : std_ulogic;
    signal lut_data         : std_ulogic_vector(15 downto 0);
    signal lut_index        : unsigned(5 downto 0);
    signal msetup_st        : std_ulogic_vector(3 downto 0);
begin
    p_control_clock : process
    begin
        wait until rising_edge(iclk);
        if irst_n = '0' then
            mi2c_ctrl_clk   <= '0';
            mi2c_clk_div    <= (others => '0');
        else
            if mi2c_clk_div < CLK_FREQ / I2C_FREQ then
                mi2c_clk_div <= mi2c_clk_div + 1;
            else
                mi2c_clk_div <= (others => '0');
                mi2c_ctrl_clk <= not mi2c_ctrl_clk;
            end if;
        end if;
    end process p_control_clock;
    
    i_i2c_controller : entity work.i2c_controller
        port map
        (
            clock           => mi2c_ctrl_clk,
            i2c_sclk        => i2c_sclk,
            i2c_sdat        => i2c_sdat,
            i2c_data        => mi2c_data,
            go              => mi2c_go,
            e_nd            => mi2c_end,
            ack             => mi2c_ack,
            reset_n         => irst_n
        );
    
end architecture rtl;