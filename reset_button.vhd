library ieee;
use ieee.std_logic_1164.all;

-- the DECA buttons have reverse logic (pressed = LOW)

entity reset_button is
    port
    (
        clk             : in std_logic;
        button          : in std_logic;
        reset_out_n     : out std_logic
    );
end entity reset_button;
        
architecture rtl of reset_button is
    signal sync_button  : std_logic_vector(1 downto 0);
begin
    p_sync_button : process
    begin
        wait until rising_edge(clk);
        sync_button <= sync_button(0) & button;
        reset_out_n <= sync_button(1);
    end process p_sync_button;
end architecture rtl;
