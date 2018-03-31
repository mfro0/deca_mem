library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_reset is
    generic
    (
        WAIT_TICKS      : integer := 1000
    );
    
    port
    (
        clk             : in std_logic;
        lock_pll        : in std_logic;
        reset_button_n  : in std_logic;
        reset_n         : out std_logic
    );
end entity deca_reset;

architecture rtl of deca_reset is
    signal counter      : integer := WAIT_TICKS;
begin
    p_reset_delay : process
    begin
        wait until rising_edge(clk);
        if counter /= 0 then
            counter <= counter - 1;
        else
            -- reset_n <= reset_button_n and lock_pll;     -- PLL does not lock when it's optimized away
            reset_n <= reset_button_n;
        end if;
    end process p_reset_delay;
end architecture rtl;

