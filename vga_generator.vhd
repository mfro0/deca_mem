library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_generator is
    port
    (
        clk             : in std_ulogic;
        reset_n         : in std_ulogic;
        
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
        v_active_34     : in integer range 0 to 4095;
        
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
    signal pixel_x      : unsigned(7 downto 0);
    signal h_act,
           h_act_d,
           v_act,
           v_act_d,
           pre_vga_de   : std_ulogic;
    signal h_max, 
           hs_end, 
           hr_start, 
           hr_end,
           v_max,
           vs_end,
           vr_start,
           vr_end       : std_ulogic;
    signal v_act_14,
           v_act_24,
           v_act_34     : std_ulogic;
    signal border       : std_ulogic;
    signal color_mode   : unsigned(3 downto 0);
    
begin
    h_max <= '1' when h_count = h_total else '0';
    hs_end <= '1' when h_count >= h_sync else '0';
    hr_start <= '1' when h_count = h_start else '0';
    hr_end <= '1' when h_count = h_end else '0';
    v_max <= '1' when v_count = v_total else '0';
    vs_end <= '1' when v_count >= v_sync else '0';
    vr_start <= '1' when v_count = v_start else '0';
    vr_end <= '1' when v_count = v_end else '0';
    v_act_14 <= '1' when v_count = v_active_14 else '0';
    v_act_24 <= '1' when v_count = v_active_24 else '0';
    v_act_34 <= '1' when v_count = v_active_34 else '0';
    
    -- horizontal control signals
    p_horiz : process
    begin
        wait until rising_edge(clk);
        if reset_n = '0' then
            h_act_d <= '1';
            h_count <= 0;
            pixel_x <= (others => '0');
            vga_hs <= '1';
            h_act <= '0';
        else
            h_act_d <= h_act;
            if h_max = '1' then
                h_count <= 0;
            else
                h_count <= h_count + 1;
            end if;
            
            if h_act_d = '1' then
                pixel_x <= pixel_x + 1;
            else
                pixel_x <= (others => '0');
            end if;
            
            if hs_end = '1' and not h_max = '1' then
                vga_hs <= '1';
            else
                vga_hs <= '0';
            end if;
            
            if hr_start = '1' then
                h_act <= '1';
            else
                h_act <= '0';
            end if;
        end if;
    end process p_horiz;
    
    -- vertical control signals
    p_vert : process
    begin
        wait until rising_edge(clk);
        if reset_n = '0' then
            v_act_d <= '0';
            v_count <= 0;
            vga_vs <= '1';
            v_act <= '0';
            color_mode <= (others => '0');
        else
            if h_max = '1' then
                v_act_d <= v_act;
                
                if v_max = '1' then
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
                
                if vr_start then
                    color_mode(0) <= '1';
                elsif v_act_14 then
                    color_mode(0) <= '0';
                end if;
                
                if v_act_14 then
                    color_mode(1) <= '1';
                elsif v_act_24 then
                    color_mode(1) <= '0';
                end if;
                
                if v_act_24 then
                    color_mode(2) <= '1';
                elsif v_act_34 then
                    color_mode(2) <= '0';
                end if;
                
                if v_act_34 then
                    color_mode(3) <= '1';
                elsif vr_end then
                    color_mode(3) <= '0';
                end if;
            end if;
        end if;
    end process p_vert;
    
    -- pattern generator and display enable
    p_pattern : process
    begin
        wait until rising_edge(clk);
        if not reset_n then
            vga_de <= '0';
            pre_vga_de <= '0';
            border <= '0';
        else
            vga_de <= pre_vga_de;
            pre_vga_de <= v_act and h_act;
            
            if (h_act_d = '0' and h_act = '1') or (hr_end = '1') or 
               (v_act_d = '0' and v_act = '1') or (vr_end = '1') then
                border <= '1';
            else
                border <= '0';
                if border then
                    vga_r <= x"ff";
                    vga_g <= x"ff";
                    vga_b <= x"ff";
                else
                    case color_mode is
                        when 4d"1" => 
                            vga_r <= std_ulogic_vector(pixel_x);
                            vga_g <= 8x"0";
                            vga_b <= 8x"0";
                        when 4d"2" => 
                            vga_r <= 8x"0";
                            vga_g <= std_ulogic_vector(pixel_x);
                            vga_b <= 8x"0";
                        when 4d"4" => 
                            vga_r <= 8x"0";
                            vga_g <= 8x"0";
                            vga_b <= std_ulogic_vector(pixel_x);
                        when 4d"8" => 
                            vga_r <= std_ulogic_vector(pixel_x);
                            vga_g <= std_ulogic_vector(pixel_x);
                            vga_b <= std_ulogic_vector(pixel_x);
                        when others => 
                            vga_r <= 8x"0";
                            vga_g <= 8x"0";
                            vga_b <= 8x"0";
                    end case;
                end if;
            end if;
        end if;
    end process p_pattern;
end architecture rtl;