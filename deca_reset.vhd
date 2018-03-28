library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_reset is
    generic
    (
        WAIT_TICKS      : integer := 100
    );
    
    port
    (
        clk             : in std_ulogic;
        lock_pll        : in std_ulogic;
        reset_n         : out std_ulogic
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
            if lock_pll then
                reset_n <= '1';
            end if;
        end if;
    end process p_reset_delay;
end architecture rtl;