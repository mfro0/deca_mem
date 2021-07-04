library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
	generic(
		clock_speed : integer := 50000000;
		baud : integer := 19200
	);
	port(
		clk : in std_logic;
		busy : out std_logic := '0';
		data : out std_logic_vector(7 downto 0) := (others => '0');
		rx_line : in std_logic
	);
end uart_rx;

architecture behavioural of uart_rx is
	constant prscl_max : integer range 0 to (clock_speed / baud) - 1 := (clock_speed / baud) - 1;
--	constant prscl_half : integer range 0 to ((clock_speed / baud) - 1) / 2 := ((clock_speed / baud) - 1) / 2;
-- lkmiller: Es ist das übliche "off by one" Problem, das "nichts ausmacht", so lange 
--           die Zahl groß (und mithin der Fehler klein) genug ist   ;-)
	constant prscl_half : integer range 0 to ((clock_speed / baud / 2) - 1) := ((clock_speed / baud / 2) - 1);
	signal rxd_sr : std_logic_vector(3 downto 0) := (others => '1');
	signal rxsr : std_logic_vector(7 downto 0) := (others => '0');
	signal rxbitcnt : integer range 0 to 9 := 9;
	signal rxcnt : integer range 0 to prscl_max;
begin
	process
	begin
		wait until rising_edge(clk);
		rxd_sr <= rxd_sr(rxd_sr'left -1  downto 0) & rx_line;
		if (rxbitcnt < 9) then
			if (rxcnt < prscl_max) then
				rxcnt <= rxcnt + 1;
			else
				rxcnt <= 0;
				rxbitcnt <= rxbitcnt + 1;
				rxsr <= rxd_sr(rxd_sr'left - 1) & rxsr(rxsr'left downto 1);
			end if;
		else
			if (rxd_sr(3 downto 2) = "10") then
				rxcnt <= prscl_half;
				rxbitcnt <= 0;
			end if;
		end if;
	end process;

	data <= rxsr;
	busy <= '1' when (rxbitcnt < 9) else '0';
	
end behavioural;