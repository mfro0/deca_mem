library ieee;
use ieee.std_logic_1164.all;

entity deca_clocks is
    port
    (
        clk             : in std_ulogic;
        reset_n         : in std_ulogic;
        clk_100         : out std_ulogic;
        clk_125         : out std_ulogic;
        clk_150         : out std_ulogic;
        clk_175         : out std_ulogic;
        clk_200         : out std_ulogic;
        
        locked          : out std_ulogic
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