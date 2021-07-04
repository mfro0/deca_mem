library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crc7 is
	port
    (
		clk     : in std_ulogic;
		reset   : in std_ulogic;
		enable  : in std_ulogic;
		input   : in std_ulogic;
		crc     : out std_ulogic_vector(6 downto 0)
	);
end crc7;

architecture rtl of crc7 is
	signal inv      : std_ulogic := '0';
	signal r_crc    : std_ulogic_vector(6 downto 0) := (others => '0');

begin

	inv <= input xor r_crc(6);
	
	crc <= r_crc;
	
	process
	begin
		wait until (rising_edge(clk));
		if reset = '1' then
			r_crc <= (others => '0');
		elsif enable = '1' then
            r_crc(6) <= r_crc(5);
			r_crc(5) <= r_crc(4);
			r_crc(4) <= r_crc(3);
			r_crc(3) <= r_crc(2) xor inv;
			r_crc(2) <= r_crc(1);
			r_crc(1) <= r_crc(0);
			r_crc(0) <= inv;
		end if;
	end process;

end rtl;