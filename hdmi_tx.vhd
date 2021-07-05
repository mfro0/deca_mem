library ieee;
use ieee.std_logic_1164.all;

entity hdmi_tx is
    generic
    (
        CLK_FREQUENCY       : integer;
        I2C_FREQUENCY       : integer
    );
    port
    (
        clk_50              : in std_ulogic;
        reset_n             : in std_ulogic;

        -- HDMI chip config
        hdmi_i2c_scl        : inout std_ulogic;                      -- i2c clock
        hdmi_i2c_sda        : inout std_ulogic;                      -- i2c data

        -- HDMI inter-IC sound bus
        hdmi_i2s            : inout std_ulogic_vector(3 downto 0);   --
        hdmi_lrclk          : inout std_ulogic;                      -- i2s lrclk
        hdmi_mclk           : inout std_ulogic;
        hdmi_sclk           : inout std_ulogic;

        -- HDMI video
        hdmi_tx_clk         : out std_ulogic;
        hdmi_tx_d           : out std_ulogic_vector(23 downto 0);
        hdmi_tx_de          : out std_ulogic;
        hdmi_tx_hs          : out std_ulogic;

        -- HDMI interrupt
        hdmi_tx_int         : in std_ulogic;
        hdmi_tx_vs          : out std_ulogic;

        -- DEBUG
        hdmi_configured     : out std_ulogic;
        ack_error           : out std_ulogic;
        i2c_busy            : out std_ulogic;
        i2c_verify_start    : in std_ulogic;
        reset_button_n      : in std_ulogic
    );
end entity hdmi_tx;

architecture rtl of hdmi_tx is
begin
    i_video_pattern_generator : entity work.vpg
        port map
        (
            clk_50                  => clk_50,
            reset_n                 => reset_n,

            vpg_pclk_out            => hdmi_tx_clk,                 -- pixel clock

            vpg_de                  => hdmi_tx_de,                  -- display enable
            vpg_hs                  => hdmi_tx_hs,                  -- horizontal sync
            vpg_vs                  => hdmi_tx_vs,                  -- vertical sync

            vpg_r                   => hdmi_tx_d(23 downto 16),     -- red pixel data
            vpg_g                   => hdmi_tx_d(15 downto 8),      -- green pixel data
            vpg_b                   => hdmi_tx_d(7 downto 0)        -- blue pixel data
        );

    i_i2c_hdmi_config : entity work.i2c_hdmi_config
        generic map
        (
            CLK_FREQUENCY           => CLK_FREQUENCY,
            I2C_FREQUENCY           => I2C_FREQUENCY
        )
        port map
        (
            clk                     => clk_50,
            reset_n                 => reset_n,

            i2c_sclk                => hdmi_i2c_scl,
            i2c_sdat                => hdmi_i2c_sda,
            hdmi_tx_int             => hdmi_tx_int,

            configured              => hdmi_configured,

            -- debug
            ack_error               => ack_error,
            reset_button_n          => reset_button_n,
            i2c_busy                => i2c_busy,
            verify_start            => i2c_verify_start
        );
end architecture rtl;

