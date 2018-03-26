library ieee;
use ieee.std_logic_1164.all;

entity vpg is
    port
    (
        clk_50              : in std_ulogic;
        reset_n             : in std_ulogic;
    
        vpg_pclk_out        : out std_ulogic;
        vpg_de              : out std_ulogic;
        vpg_hs              : out std_ulogic;
        vpg_vs              : out std_ulogic;
        vpg_r,
        vpg_g,
        vpg_b               : out std_ulogic_vector(7 downto 0)
    );
end entity vpg;

architecture rtl of vpg is
begin
end architecture rtl;