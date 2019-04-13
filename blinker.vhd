library ieee;
use ieee.std_logic_1164.all;

entity blinker is
    generic
    (
        CLK_FREQUENCY       : integer := 50000000;
        BLINKS_PER_SECOND   : integer := 2          -- blink every half second at 50 MHz clock
    );
    port
    (
        clk             : in std_logic;
        reset_n         : in std_logic;
        led             : out std_logic
    );
end entity blinker;

architecture rtl of blinker is
    signal counter          : integer := 0;
    signal led_out          : std_logic := '0';
    constant COUNTER_MAX    : integer := CLK_FREQUENCY / BLINKS_PER_SECOND;
begin
    p_blink : process(all)
    begin
        if not reset_n then
            counter <= 0;
            led_out <= '1';                         -- LED off
        elsif rising_edge(clk) then
            if counter = COUNTER_MAX then
                counter <= 0;
                led_out <= not led_out;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process p_blink;
    led <= led_out;
end architecture rtl;
