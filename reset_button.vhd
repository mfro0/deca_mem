library ieee;
use ieee.std_logic_1164.all;

-- the DECA buttons have reverse logic (pressed = LOW)

entity sync_button is
    port
    (
        clk             : in std_ulogic;
        button          : in std_ulogic;
        button_out_n    : out std_ulogic
    );
end entity sync_button;
        
architecture rtl of sync_button is
    signal sync_button  : std_ulogic_vector(1 downto 0);
begin
    p_sync_button : process
    begin
        wait until rising_edge(clk);
        sync_button <= sync_button(0) & button;
        button_out_n <= sync_button(1);
    end process p_sync_button;
end architecture rtl;
