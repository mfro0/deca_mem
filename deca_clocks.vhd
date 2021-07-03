library ieee;
use ieee.std_logic_1164.all;

entity deca_clocks is
    port
    (
        clk             : in std_ulogic;
        reset_n         : in std_ulogic;
        clk_1536k       : out std_ulogic;
        clk_150         : out std_ulogic;
        locked          : out std_ulogic
    );
end entity deca_clocks;

architecture rtl of deca_clocks is
    signal reset        : std_logic;
begin
    reset <= not reset_n;
    
    i_pll : entity work.pll
        port map
        (
            inclk0      => clk,
            areset      => reset_n,
            c0          => clk_1536k,
            c1          => clk_150,
            locked      => locked
        );
end architecture rtl;
