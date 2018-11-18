library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.m68k_binary.all;

entity simple_memory is

    generic
    (
        DATA_WIDTH      : natural;       -- the width (in bits) of the memory data port
        ADDR_WIDTH      : natural        -- the witth (in bits) of the memory address port
    );

    port
    (
        clk             : in std_logic;
        reset_n         : in std_logic;
        
        addr_in         : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        data            : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        we              : in std_logic := '1';
        q               : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );

end simple_memory;

architecture rtl of simple_memory is

    -- Build a 2-D array type for the RAM
    subtype word_t is std_logic_vector(DATA_WIDTH - 1 downto 0);
    type memory_type is array(2 ** ADDR_WIDTH - 1 downto 0) of word_t;

    function init_ram return memory_type is
        variable tmp    : memory_type := (others => (others => '0'));
        variable addr   : natural := 0;
        variable i      : natural := 0;
        variable data   : word_t;
    begin

        while i < m68k_binary'length - 4 loop
            for j in DATA_WIDTH / 8 - 1 downto 0 loop
                tmp(addr)((j + 1) * 8 - 1 downto j * 8) := m68k_binary(i + 3 - j);
            end loop;
            i := i + DATA_WIDTH / 8;
            addr := addr + 1;
        end loop;

        return tmp;
    end init_ram;

    -- Declare the RAM signal and specify a default value.  Quartus Prime
    -- will create a memory initialization file (.mif) based on the
    -- default value.
    signal ram : memory_type := init_ram;

    -- Register to hold the address
    signal addr_reg : natural range 0 to 2 ** ADDR_WIDTH - 1;
    signal addr     : natural range 0 to 2 ** ADDR_WIDTH - 1;

begin
    addr <= to_integer(unsigned(addr_in));

    process
    begin
        wait until rising_edge(clk);
        if not reset_n then
            null;
        else
            if we then
                ram(addr) <= data;
            end if;

            -- Register the address for reading
            addr_reg <= addr;
        end if;
    end process;

    q <= ram(addr_reg);
end rtl;
