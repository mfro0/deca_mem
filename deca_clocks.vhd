library ieee;
use ieee.std_logic_1164.all;

entity deca_clocks is
    port
    (
        clk             : in std_logic;
        reset_n         : in std_logic;
        clk_1536k       : out std_logic;
        
        locked          : out std_logic
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
            locked      => locked
        );
end architecture rtl;
