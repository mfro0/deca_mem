library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library altera_mf;
use altera_mf.all;

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
        v_end           : v_int;
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
    constant video_timings  : video_timings_array_type :=
    (
        (
            -- 640x480@60 25.175 MHZ
            h_total => 799, h_sync => 95, h_start => 141, h_end => 781,
            v_total => 524, v_sync => 1, v_start => 54, v_end => 741
        ),
        (
            -- 720x480@60 27MHZ (VIC=3, 480P)
            h_total => 857, h_sync => 61, h_start => 119, h_end => 839,
            v_total => 524, v_sync => 5, v_start => 35, v_end => 515
        ),
        (
            -- 1024x768@60 65MHZ (XGA)
            h_total => 1343, h_sync => 135, h_start => 293, h_end => 1317,
            v_total => 805, v_sync => 5, v_start => 34, v_end => 802
        ),
        (
            -- 1280x1024@60   108MHZ (SXGA)
            h_total => 1687, h_sync => 111, h_start => 357, h_end => 1637,
            v_total => 1065, v_sync => 2, v_start => 40, v_end => 1064
        ),
        (
            -- 1920x1080p60 148.5MHZ
            h_total => 2199, h_sync => 43, h_start => 189, h_end => 2109,
            v_total => 1124, v_sync => 4, v_start => 40, v_end => 1120
        ),
        /*
        (
            -- 1920x1080p60 148.5MHZ
            h_total => 2199, h_sync => 88, h_start => 191, h_end => 2109,
            v_total => 1124, v_sync => 4, v_start => 45, v_end => 1120
        ),
        */
        (
            -- 1600x1200p60 162MHZ (VESA)
            h_total => 2159, h_sync => 191, h_start => 493, h_end => 2093,
            v_total => 1249, v_sync => 2, v_start => 48, v_end => 1248
        )
    );
    constant v          : video_timing_type := video_timings(5);        -- select 1920 x 1080

    -- cut timing path for reset_n in pixel clock domain
    signal synced_reset             : std_ulogic_vector(1 downto 0);
    attribute altera_attribute      : string;
    attribute altera_attribute of synced_reset : signal is "-name SDC_STATEMENT ""set_false_path " &
                                                           "-from [get_registers *reset_n*] " &
                                                           "-to [get_registers *synced_reset[*]*];""";
    signal reset                    : std_ulogic;

begin
    reset <= not reset_n;

    i_video_pll : entity work.video_pll
        port map
        (
            inclk0          => clk_50,
            areset          => reset,
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
            vga_hs          => vpg_hs,
            vga_vs          => vpg_vs,
            vga_de          => vpg_de,
            vga_r           => vpg_r,
            vga_g           => vpg_g,
            vga_b           => vpg_b
        );
    
    b_video_reconfig : block
        signal reconfig_busy                : std_ulogic;
        signal reconfig_counter_param       : std_ulogic_vector(2 downto 0);
        signal reconfig_counter_type        : std_ulogic_vector(3 downto 0);
        signal reconfig_data                : std_ulogic_vector(8 downto 0);
        signal reconfig_data_out            : std_ulogic_vector(8 downto 0);
        signal reconfig_pll_areset          : std_ulogic;
        signal reconfig_pll_areset_in       : std_ulogic;
        signal reconfig_pll_configupdate    : std_ulogic;
        signal reconfig_pll_scanaclr        : std_ulogic;
        signal reconfig_pll_scanclk         : std_ulogic;
        signal reconfig_pll_scanclkena      : std_ulogic;
        signal reconfig_pll_scandata        : std_ulogic;
        signal reconfig_pll_scandataout     : std_ulogic;
        signal reconfig_pll_scandone        : std_ulogic;
        signal reconfig_pll_scanread        : std_ulogic;
        signal reconfig_pll_scanwrite       : std_ulogic;
        signal reconfig_read_param          : std_ulogic;
        signal reconfig                     : std_ulogic;
        signal reset                        : std_ulogic;
    begin
        i_video_reconfig : component altera_mf_components.altpll_reconfig
            generic map
            (
                null
            )   
            port map
            (
                clock                       => clk_50,
                busy                        => reconfig_busy,
                counter_param               => std_logic_vector(reconfig_counter_param),
                counter_type                => std_logic_vector(reconfig_counter_type),
                data_in                     => std_logic_vector(reconfig_data),
                std_ulogic_vector(data_out) => reconfig_data_out,
                pll_areset                  => reconfig_pll_areset,
                pll_areset_in               => reconfig_pll_areset_in,
                pll_configupdate            => reconfig_pll_configupdate,
                pll_scanaclr                => reconfig_pll_scanaclr,
                pll_scanclk                 => reconfig_pll_scanclk,
                pll_scanclkena              => reconfig_pll_scanclkena,
                pll_scandata                => reconfig_pll_scandata,
                pll_scandataout             => reconfig_pll_scandataout,
                pll_scandone                => reconfig_pll_scandone,
                pll_scanread                => reconfig_pll_scanread,
                pll_scanwrite               => reconfig_pll_scanwrite,
                read_param                  => reconfig_read_param,
                reconfig                    => reconfig,
                reset                       => reset,
                reset_rom_address           => open,
                rom_address_out             => open,
                rom_data_in                 => open,
                write_from_rom              => open,
                write_param                 => open,
                write_rom_ena               => open
            );
        -- now connect our pll reconfig entity to the relevant signals 
    end block b_video_reconfig;
    
end architecture rtl;
