library ieee;
use ieee.std_logic_1164.all;

entity blinker is
    generic
    (
        COUNTER_MAX     : integer := 50000000   -- blink every second at 50 MHz clock
    );
    port
    (
        clk             : in std_ulogic;
        reset_n         : in std_ulogic;
        led             : out std_ulogic
    );
end entity blinker;

architecture rtl of blinker is
    signal counter      : integer := 0;
    signal led_out      : std_ulogic := '0';
begin
    p_blink : process
    begin
        wait until rising_edge(clk);
        if not reset_n then
            counter <= 0;
            led_out <= '1';                     -- LED off
        end if;
        if counter = COUNTER_MAX then
            counter <= 0;
            led_out <= not led_out;
        else
            counter <= counter + 1;
        end if;
    end process p_blink;
    led <= led_out;
end architecture rtl;