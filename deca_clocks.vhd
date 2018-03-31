library ieee;
use ieee.std_logic_1164.all;

entity deca_clocks is
    port
    (
        clk             : in std_logic;
        reset_n         : in std_logic;
        clk_100         : out std_logic;
        clk_125         : out std_logic;
        clk_150         : out std_logic;
        clk_175         : out std_logic;
        clk_200         : out std_logic;
        
        locked          : out std_logic
    );
end entity deca_clocks;

architecture rtl of deca_clocks is
begin
    i_pll : entity work.pll
        port map
        (
            inclk0      => clk,
            areset      => reset_n,
            c0          => clk_100,
            c1          => clk_125,
            c2          => clk_150,
            c3          => clk_175,
            c4          => clk_200,
            locked      => locked
        );
end architecture rtl;
