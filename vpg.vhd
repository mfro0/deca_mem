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
    
    subtype v_int is integer range 0 to 4095;       -- 12 bits
    type video_timing_type is record
        h_total,
        h_sync,
        h_start,
        h_end,
        v_total,
        v_sync,
        v_start,
        v_end,
        v_active_14,
        v_active_24,
        v_active_34         : v_int;
    end record video_timing_type;
    type video_timings_array_type is array(natural range <>) of video_timing_type;
    
    -- h_total : total - 1
    -- h_sync : sync - 1
    -- h_start : sync + back porch - 1 - 2 (delay)
    -- h_end : h_start + active
    -- v_total : total - 1
    -- v_sync : sync - 1
    -- v_start : sync + back porch - 1
    -- v_end : v_start + active
    -- v_active_14 : v_start + 1/4 active
    -- v_active_24 : v_start + 2/4 active
    -- v_active_34 : v_start + 3/4 active
    constant video_timings  : video_timings_array_type :=
    (
        ( 
            -- 640x480@60 25.175 MHZ
            h_total => 799, h_sync => 95, h_start => 141, h_end => 781,
            v_total => 524, v_sync => 1, v_start => 54, v_end => 741,
            v_active_14 => 154, v_active_24 => 274, v_active_34 => 394
        ),
        (
            -- 720x480@60 27MHZ (VIC=3, 480P)
            h_total => 857, h_sync => 61, h_start => 119, h_end => 839,
            v_total => 524, v_sync => 5, v_start => 35, v_end => 515,
            v_active_14 => 155, v_active_24 => 275, v_active_34 => 395
        ), 
        (
            -- 1024x768@60 65MHZ (XGA)
            h_total => 1343, h_sync => 135, h_start => 293, h_end => 1317,
            v_total => 805, v_sync => 5, v_start => 34, v_end => 802,
            v_active_14 => 226, v_active_24 => 418, v_active_34 => 610
        ),  
        (
            -- 1280x1024@60   108MHZ (SXGA)
            h_total => 1687, h_sync => 111, h_start => 357, h_end => 1637,
            v_total => 1065, v_sync => 2, v_start => 40, v_end => 1064,
            v_active_14 => 296, v_active_24 => 552, v_active_34 => 808
        ),
        (
            -- 1920x1080p60 148.5MHZ
            h_total => 2199, h_sync => 43, h_start => 189, h_end => 2109,
            v_total => 1124, v_sync => 4, v_start => 40, v_end => 1120,
            v_active_14 => 310, v_active_24 => 580, v_active_34 => 850
        ),
        (
            -- 1600x1200p60 162MHZ (VESA)
            h_total => 2159, h_sync => 191, h_start => 493, h_end => 2093,
            v_total => 1249, v_sync => 2, v_start => 48, v_end => 1248,
            v_active_14 => 348, v_active_24 => 648, v_active_34 => 948
        )
    );
    constant v          : video_timing_type := video_timings(5);        -- select 1600 x 1200 for now (must fit video_pll settings)
    
    -- cut timing path for reset_n in pixel clock domain
    signal synced_reset             : std_ulogic_vector(1 downto 0);
    attribute altera_attribute      : string;
    attribute altera_attribute of synced_reset : signal is "-name SDC_STATEMENT ""set_false_path " &
                                                           "-from [get_registers *reset_n*] " &
                                                           "-to [get_registers *synced_reset[*]*];""";
begin
    i_video_pll : entity work.video_pll
        port map
        (
            inclk0          => clk_50,
            areset          => not reset_n,
            c0              => vpg_pclk
        );
    vpg_pclk_out <= not vpg_pclk;
    
    -- synchronize reset signal into pixel clk domain
    p_sync_reset : process
    begin
        wait until rising_edge(vpg_pclk);
        synced_reset <= synced_reset(0) & reset_n;
    end process p_sync_reset;
    
    i_vga_generator : entity work.vga_generator
        port map
        (
            clk             => vpg_pclk,
            reset_n         => synced_reset(1),
            h_total         => v.h_total,
            h_sync          => v.h_sync,
            h_start         => v.h_start,
            h_end           => v.h_end,
            v_total         => v.v_total,
            v_sync          => v.v_sync,
            v_start         => v.v_start,
            v_end           => v.v_end,
            v_active_14     => v.v_active_14,
            v_active_24     => v.v_active_24,
            v_active_34     => v.v_active_34,
            vga_hs          => vpg_hs,
            vga_vs          => vpg_vs,
            vga_de          => vpg_de,
            vga_r           => vpg_r,
            vga_g           => vpg_g,
            vga_b           => vpg_b
        );
end architecture rtl;