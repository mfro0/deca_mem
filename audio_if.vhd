library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_if is
    generic
    (
        DATA_WIDTH      : integer := 16
    );
        port
    (
        clk             : in std_logic;
        reset_n         : in std_logic;
        
        sclk            : out std_logic;
        lrclk           : out std_logic;
        i2s             : out std_logic_vector(3 downto 0)
    );
end entity audio_if;

architecture rtl of audio_if is
    subtype sintab_entry_type is integer range 0 to 65535;
    type sintab_type is array(natural range <>) of sintab_entry_type;
    constant sintab     : sintab_type :=
    (
            0,  4276,  8480, 12539, 16383, 19947, 23169, 25995,
        28377, 30272, 31650, 32486, 32767, 32486, 31650, 30272,
        28377, 25995, 23169, 19947, 16383, 12539,  8480,  4276,
            0, 61259, 57056, 52997, 49153, 45589, 42366, 39540,
        37159, 35263, 33885, 33049, 32768, 33049, 33885, 35263,
        37159, 39540, 42366, 45589, 49152, 52997, 57056, 61259
    );
    
    signal sclk_count   : integer range 0 to 31;
    signal data_count   : integer range 0 to 63;
    signal sin_count    : integer range 0 to sintab'high;
    signal sclk_i,
           lrclk_i      : std_logic;
begin
    sclk <= sclk_i;
    lrclk <= lrclk_i;
    
    p_lrclk : process(all)
    begin
        if not reset_n then
            lrclk_i <= '0';
            sclk_count <= 0;
        elsif falling_edge(clk) then
            if sclk_count >= DATA_WIDTH - 1 then
                sclk_count <= 0;
                lrclk_i <= not lrclk_i;
            else
                sclk_count <= sclk_count + 1;
            end if;
        end if;
    end process p_lrclk;
    
    p_sclk : process(all)
    begin
        if not reset_n then
            data_count <= 0;
        elsif falling_edge(clk) then
            if data_count = DATA_WIDTH - 1 then
                data_count <= 0;
            else
                data_count <= data_count + 1;
            end if;
        end if;
    end process p_sclk;
    
    p_bits_out : process(all)
        variable sample : std_logic_vector(15 downto 0);
    begin
        if not reset_n then
            i2s <= (others => '0');
        elsif falling_edge(clk) then
            sample := std_logic_vector(to_unsigned(sintab(DATA_WIDTH - 1 - sin_count), 16));
            i2s(0) <= sample(data_count);
            i2s(1) <= sample(data_count);
            i2s(2) <= sample(data_count);
            i2s(3) <= sample(data_count);
        end if;
    end process p_bits_out;
    
    p_sincount : process(all)
    begin
        if not reset_n then
            sin_count <= 0;
        elsif falling_edge(lrclk_i) then
            if sin_count < sintab'high then
                sin_count <= sin_count + 1;
            else
                sin_count <= 0;
            end if;
        end if;
    end process p_sincount;
end architecture rtl;
    
