library ieee;
use ieee.std_logic_1164.all;

entity hdmi_tx is
    port
    (
        clk_50              : in std_ulogic;
        reset_n             : in std_ulogic;
        
        hdmi_i2c_scl        : inout std_ulogic;
        hdmi_i2c_sda        : inout std_ulogic;
        hdmi_i2s            : inout std_ulogic_vector(3 downto 0);
        hdmi_lrclk          : inout std_ulogic;
        hdmi_mclk           : inout std_ulogic;
        hdmi_sclk           : inout std_ulogic;
        hdmi_tx_clk         : out std_ulogic;
        hdmi_tx_d           : out std_ulogic_vector(23 downto 0);
        hdmi_tx_de          : out std_ulogic;
        hdmi_tx_hs          : out std_ulogic;
        hdmi_tx_int         : in std_ulogic;
        hdmi_tx_vs          : out std_ulogic
    );
end entity hdmi_tx;

architecture rtl of hdmi_tx is
begin
    i_video_pattern_generator : entity work.video_pattern_generator
        port map
        (
            clk_50              => clk_50,
            reset_n             => reset_n,
            vpg_pclk_out        => hdmi_tx_clk,
            vpg_de              => hdmi_tx_de,
            vpg_hs              => hdmi_tx_hs,
            vpg_vs              => hdmi_tx_vs,
            vpg_r               => hdmi_tx_d(23 downto 16),
            vpg_g               => hdmi_tx_d(15 downto 8),
            vpg_b               => hdmi_tx_d(7 downto 0)
        );
end architecture rtl;
        