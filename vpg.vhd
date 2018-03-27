library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vpg is
    port
    (
        clk_50              : in std_ulogic;
        reset_n             : in std_ulogic;
    
        vpg_pclk_out        : out std_ulogic;
        vpg_de              : out std_ulogic;
        vpg_hs              : out std_ulogic;
        vpg_vs              : out std_ulogic;
        vpg_r,
        vpg_g,
        vpg_b               : out std_ulogic_vector(7 downto 0)
    );
end entity vpg;

architecture rtl of vpg is
    signal vpg_pclk         : std_ulogic;
    signal h_total,
           h_sync,
           h_start,
           h_end            : unsigned(11 downto 0);
    signal v_total,
           v_sync,
           v_start,
           v_end            : unsigned(11 downto 0);
    signal v_active_14,
           v_active_24,
           v_active_34      : unsigned(11 downto 0);
begin
    i_video_pll : entity work.video_pll
        port map
        (
            inclk0          => clk_50,
            areset          => not reset_n,
            c0              => vpg_pclk
        );
    vpg_pclk_out <= not vpg_pclk;
    
    i_vga_generator : entity work.vga_generator
        port map
        (
            clk             => vpg_pclk,
            reset_n         => reset_n,
            h_total         => h_total,
            h_sync          => h_sync,
            h_start         => h_start,
            h_end           => h_end,
            v_total         => v_total,
            v_sync          => v_sync,
            v_start         => v_start,
            v_end           => v_end,
            v_active_14     => v_active_14,
            v_active_24     => v_active_24,
            v_active_34     => v_active_34,
            vga_hs          => vpg_hs,
            vga_vs          => vpg_vs,
            vga_de          => vpg_de,
            vga_r           => vpg_r,
            vga_g           => vpg_g,
            vga_b           => vpg_b
        );
        
    -- 1920 x 1080p60, 148,5 MHz
    h_total <= 12d"2199";
    h_sync <= 12d"43";
    h_start <= 12d"189";
    h_end <= 12d"2109";
    v_total <= 12d"1124";
    v_sync <= 12d"4";
    v_start <= 12d"40";
    v_end <= 12d"1120";
    v_active_14 <= 12d"310";
    v_active_24 <= 12d"580";
    v_active_34 <= 12d"850";
end architecture rtl;