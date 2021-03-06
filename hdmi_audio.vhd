library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_audio is
    generic
    (
        CLK_FREQUENCY,
        SCLK_FREQUENCY  : natural
    );
    port
    (
        clk             : in std_ulogic;
        reset_n         : in std_ulogic;
        
        sclk,
        lrclk           : out std_ulogic;
        i2s             : out std_ulogic_vector(3 downto 0)
    );
end entity hdmi_audio;

architecture rtl of hdmi_audio is
    subtype sintab_entry_type is integer range 0 to 65535;
    type sintab_type is array (natural range <>) of sintab_entry_type;
    constant sintab             : sintab_type :=
    (
            0,  4276,  8480, 12539, 16383, 19947, 23169, 25995,
        28377, 30272, 31650, 32486, 32767, 32486, 31650, 30272,
        28377, 25995, 23169, 19947, 16383, 12539,  8480,  4276,
            0, 61259, 57056, 52997, 49153, 45589, 42366, 39540,
        37159, 35263, 33885, 33049, 32768, 33049, 33885, 35263,
        37159, 39540, 42366, 45589, 49152, 52997, 57056, 61259
    );
	signal bitcount,
           sclk_count,
           table_index          : integer;
    signal lrclk_i              : std_ulogic;
    
begin
    sclk <= clk;
    lrclk <= lrclk_i;
    
    p_lrclk : process(all)
    begin
        if not reset_n then
            lrclk_i <= '0';
            sclk_count <= 0;
        elsif falling_edge(clk) then
            if sclk_count > CLK_FREQUENCY / SCLK_FREQUENCY - 1 then
                sclk_count <= 0;
                lrclk_i <= not lrclk_i;
            else
                sclk_count <= sclk_count + 1;
            end if;
        end if;
    end process p_lrclk;
    
    p_bitcount : process(all)
    begin
        if not reset_n then
            bitcount <= 0;
        elsif falling_edge(clk) then
            if bitcount > 15 then
                bitcount <= 0;
            else
                bitcount <= bitcount + 1;
            end if;
        end if;
    end process p_bitcount;
    
    p_tab_index : process(all)
    begin
        if not reset_n then
            table_index <= 0;
        elsif falling_edge(lrclk_i) then
            if table_index <= sintab'high then
                table_index <= table_index + 1;
            else
                table_index <= 0;
            end if;
        end if;
    end process p_tab_index;
    
    p_data_out : process(all)
        variable data : unsigned(15 downto 0);
    begin
        if not reset_n then
            i2s <= (others => '0');
        else
            data := to_unsigned(sintab(table_index), 16);
            i2s(0) <= data(15 - bitcount);
            i2s(1) <= data(15 - bitcount);
            i2s(2) <= data(15 - bitcount);
            i2s(3) <= data(15 - bitcount);
        end if;
    end process p_data_out;
end architecture rtl;