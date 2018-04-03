library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.m68k_binary.all;

entity simple_memory is

    generic 
    (
        DATA_WIDTH : natural := 16;
        ADDR_WIDTH : natural := 6
    );

    port 
    (
        clk     : in std_logic;
        reset_n : in std_logic;
        addr_in : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        data    : in std_logic_vector((DATA_WIDTH - 1) downto 0);
        we      : in std_logic := '1';
        q       : out std_logic_vector((DATA_WIDTH - 1) downto 0)
    );

end simple_memory;

architecture rtl of simple_memory is

    -- Build a 2-D array type for the RAM
    subtype word_t is std_logic_vector((DATA_WIDTH - 1) downto 0);
    type memory_t is array(2 ** ADDR_WIDTH - 1 downto 0) of word_t;

    function init_ram return memory_t is 
        variable tmp    : memory_t := (others => (others => '0'));
        variable addr   : integer := 0;
        variable i      : integer := 0;
        variable add    : integer range 0 to 3;
    begin

        while i < m68k_binary'length loop
            -- add := (i + 2) mod 4;
            add := 0;
            tmp(addr) := m68k_binary(i + add) & m68k_binary(i + add + 1);
            i := i + 2;
            addr := addr + 1;
        end loop;

        return tmp;
    end init_ram;    

    -- Declare the RAM signal and specify a default value.  Quartus Prime
    -- will create a memory initialization file (.mif) based on the 
    -- default value.
    signal ram : memory_t := init_ram;

    -- Register to hold the address 
    signal addr_reg : natural range 0 to 2 ** ADDR_WIDTH - 1;
    signal addr     : natural range 0 to 2 ** ADDR_WIDTH - 1;

begin
    addr <= to_integer(unsigned(addr_in));
    
    process(all)
    begin
        if not reset_n then
            null;
        elsif falling_edge(clk) then
            if we then
                ram(addr) <= data;
            end if;

            -- Register the address for reading
            addr_reg <= addr;
        end if;
    end process;

    q <= ram(addr_reg);
end rtl;
