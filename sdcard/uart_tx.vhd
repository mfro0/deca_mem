library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
	generic(
		clock_speed : integer := 50000000;
		baud : integer := 9600
	);
	port(
		clk : in std_logic;
		start : in std_logic;
		busy : out std_logic := '0';
		data : in std_logic_vector(7 downto 0);
		tx_line : out std_logic := '1'
	);
end uart_tx;

architecture behavioural of uart_tx is
	constant prscl_max : integer range 0 to (clock_speed / baud) - 1 := (clock_speed / baud) - 1;
--	constant prscl_half : integer range 0 to ((clock_speed / baud) - 1) / 2 := ((clock_speed / baud) - 1) / 2;
-- lkmiller: Es ist das übliche "off by one" Problem, das "nichts ausmacht", so lange 
--           die Zahl groß (und mithin der Fehler klein) genug ist   ;-)
	constant prscl_half : integer range 0 to ((clock_speed / baud / 2) - 1) := ((clock_speed / baud / 2) - 1);
	signal txstart : std_logic := '0';
	signal txsr : std_logic_vector(9 downto 0) := (others => '1');
	signal txbitcnt : integer range 0 to 10 := 10;
	signal txcnt : integer range 0 to prscl_max;

begin
	process
	begin
		wait until (rising_edge(clk));
		txstart <= start;
		if (start = '1' and txstart = '0') then
			txcnt <= 0;
			txbitcnt <= 0;
			txsr <= '1' & data & '0';
		else
			if (txcnt < prscl_max) then
				txcnt <= txcnt + 1;
			else
				if (txbitcnt < 10) then
					txcnt <= 0;
					txbitcnt <= txbitcnt + 1;
					txsr <= '1' & txsr(txsr'left downto 1);
				end if;
			end if;
		end if;
	end process;
	
	tx_line <= txsr(0);
	busy <= '1' when (start = '1' or txbitcnt < 10) else '0';
	
end behavioural;