library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_generator is
    port
    (
        clk             : in std_ulogic;
        pixel_clk       : in std_ulogic;
        reset_n         : in std_ulogic;

        h_total,
        h_sync,
        h_start,
        h_end,
        v_total,
        v_sync,
        v_start,
        v_end           : in integer range 0 to 4095;

        vga_hs,
        vga_vs,
        vga_de          : out std_ulogic;

        vga_r,
        vga_g,
        vga_b           : out std_ulogic_vector(7 downto 0)
    );
end entity vga_generator;

architecture rtl of vga_generator is
    signal h_count,
           v_count      : integer range 0 to 4095;
    subtype byte is integer range 0 to 255;
    signal pixel_x      : byte;
    signal h_act,
           h_act_d,
           v_act,
           v_act_d,
           pre_vga_de   : std_logic;
    signal h_max,
           hs_end,
           hr_start,
           hr_end,
           v_max,
           vs_end,
           vr_start,
           vr_end       : std_logic;
    signal border       : std_logic;

    type colour_mode_type is (GRAY_GRADIENT, RED_GRADIENT, GREEN_GRADIENT, BLUE_GRADIENT, YELLOW_GRADIENT, CYAN_GRADIENT, MAGENTA_GRADIENT);
    signal colour_mode   : colour_mode_type;


begin
    h_max <= '1' when h_count = h_total else '0';
    hs_end <= '1' when h_count >= h_sync else '0';
    hr_start <= '1' when h_count = h_start else '0';
    hr_end <= '1' when h_count = h_end else '0';

    v_max <= '1' when v_count = v_total else '0';
    vs_end <= '1' when v_count >= v_sync else '0';
    vr_start <= '1' when v_count = v_start else '0';
    vr_end <= '1' when v_count = v_end else '0';


    -- horizontal control signals
    p_horiz : process(all)
    begin
        if not reset_n then
            h_act_d <= '0';
            h_count <= 0;
            pixel_x <= 0;
            vga_hs <= '1';
            h_act <= '0';
        elsif rising_edge(pixel_clk) then
            h_act_d <= h_act;
            if h_max then
                h_count <= 0;
            else
                h_count <= h_count + 1;
            end if;

            if h_act_d then
                if pixel_x < byte'high then
                    pixel_x <= (pixel_x + 1) ; --mod 255;
                else
                    pixel_x <= 0;
                end if;
            else
                pixel_x <= 0;
            end if;

            if hs_end and not h_max then
                vga_hs <= '1';
            else
                vga_hs <= '0';
            end if;

            if hr_start then
                h_act <= '1';
            elsif hr_end then
                h_act <= '0';
            end if;
            
        end if;
    end process p_horiz;

    -- vertical control signals
    p_vert : process(all)
    begin
        if not reset_n then
            v_act_d <= '0';
            v_count <= 0;
            vga_vs <= '1';
            v_act <= '0';
            colour_mode <= GRAY_GRADIENT;
        elsif rising_edge(pixel_clk) then
            if h_max then
                v_act_d <= v_act;

                if v_max then
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
                end if;

                if vs_end and not v_max then
                    vga_vs <= '1';
                else
                    vga_vs <= '0';
                end if;

                if vr_start then
                    v_act <= '1';
                elsif vr_end then
                    v_act <= '0';
                end if;
            end if;

            -- set next colour mode     
            colour_mode <= colour_mode_type'val(v_count / (v_total / (colour_mode_type'pos(colour_mode_type'high) + 1)));
        end if;
    end process p_vert;

    -- pattern generator and display enable
    p_pattern : process(all)
        variable p_x    : std_ulogic_vector(7 downto 0);
        variable shift  : integer range 0 to 2047;
        variable fc     : integer range 0 to 127;
    begin
        if not reset_n then
            vga_de <= '0';
            pre_vga_de <= '0';
            border <= '0';
            shift := 0;
            fc := 0;
        elsif rising_edge(pixel_clk) then
            vga_de <= pre_vga_de;
            pre_vga_de <= v_act and h_act;
            
            if (not h_act_d and h_act) or hr_end or
               (not v_act_d and v_act) or vr_end then
                border <= '1';
            else
                border <= '0';
            end if;
            if vr_end then
                fc := fc + 1;
                if fc = 127 then
                    fc := 0;
                    shift := shift + 1; -- shift pattern every 96 frames
                end if;
            end if;
            if border then
                vga_r <= x"ff";
                vga_g <= x"ff";
                vga_b <= x"ff";
            else
                p_x := std_ulogic_vector(to_unsigned(pixel_x + shift, 8));
                
                case colour_mode is
                    when RED_GRADIENT =>
                        vga_r <= p_x;
                        vga_g <= 8x"0";
                        vga_b <= 8x"0";
                        
                    when GREEN_GRADIENT =>
                        vga_r <= 8x"0";
                        vga_g <= p_x;
                        vga_b <= 8x"0";

                    when BLUE_GRADIENT =>
                        vga_r <= 8x"0";
                        vga_g <= 8x"0";
                        vga_b <= p_x;
                        
                    when YELLOW_GRADIENT =>
                        vga_r <= p_x;
                        vga_g <= p_x;
                        vga_b <= 8x"0";
                    
                    when CYAN_GRADIENT =>
                        vga_r <= 8x"0";
                        vga_g <= p_x;
                        vga_b <= p_x;
                    
                    when MAGENTA_GRADIENT =>
                        vga_r <= p_x;
                        vga_g <= 8x"0";
                        vga_b <= p_x;
                    
                    when GRAY_GRADIENT =>
                        vga_r <= p_x;
                        vga_g <= p_x;
                        vga_b <= p_x;
                end case; 
            end if;
        end if;
    end process p_pattern;
    
    b_video_fifo : block
        signal video_fifo_aclr  : std_ulogic;
        signal video_rdrq       : std_ulogic;
        signal video_wrclk      : std_ulogic;
        signal video_data       : std_ulogic_vector(23 downto 0);
        signal video_fifo_rdata : std_ulogic_vector(23 downto 0);
        signal video_fifo_empty : std_ulogic;
        signal video_fifo_full  : std_ulogic;

    begin
        i_video_fifo : entity work.video_fifo
            port map
            (
                aclr                => video_fifo_aclr,
                data                => std_logic_vector(video_fifo_rdata),
                rdclk               => pixel_clk,
                rdreq               => video_rdrq,
                wrclk               => clk,                 -- FIXME: is this supposed to be the afi_clk?
                wrreq               => video_wrclk,
                std_ulogic_vector(q)=> video_data,
                rdempty             => video_fifo_empty,
                wrfull              => video_fifo_full
            );
            
        p_video_out : process(all)
        begin
            if not reset_n then
            elsif rising_edge(pixel_clk) then
                -- no need to observe empty or rdempty as the FIFO isn't allowed to drain by definition
                video_rdrq <= '1';
                --vga_r <= video_data(23 downto 16);
                --vga_b <= video_data(15 downto 8);
                --vga_g <= video_data(7 downto 0);
            end if;
        end process p_video_out;
    end block b_video_fifo;

end architecture rtl;
