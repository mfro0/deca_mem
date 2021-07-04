-- wait 1 clock cycle after we <= '1' and do not change data during that time !!!!!!!!!!!!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_transmitter is
	generic(
		clock_speed : integer := 50000000;
		baud : integer := 9600
	);
	port(
		clk : in std_logic;
		we : in std_logic;
		ready : out std_logic := '0';
		data : in std_logic_vector(7 downto 0);
		tx_line : out std_logic := '1'
	);
end uart_transmitter;

architecture behavioural of uart_transmitter is
	component uart_tx is
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
	end component uart_tx;

	signal tx_start : std_logic := '0';
	signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
	signal tx_busy : std_logic;

	component fifo is
		generic(
			depth : integer := 16;
			width : integer := 8
		);
		port(
			clk : in std_logic;
			re : in std_logic;
			data_out : out std_logic_vector(width-1 downto 0) := (others => '0');
			we : in std_logic;
			data_in : in std_logic_vector(width-1 downto 0);
			empty : out std_logic := '1';
			full : out std_logic := '0'
		);
	end component fifo;
	
	signal f_re : std_logic := '0';
	signal f_we : std_logic := '0';
	signal f_empty : std_logic := '1';
	signal f_full : std_logic := '0';
	
	signal cansend : std_logic := '0';
	
begin

	uart_tx_inst : uart_tx generic map( clock_speed => clock_speed, baud => baud )
			port map(
			clk => clk,
			start => tx_start,
			busy => tx_busy,
			data => tx_data,
			tx_line => tx_line
		);
		
	fifo_inst : fifo generic map( depth => 16, width => 8)
			port map(
			clk => clk,
			re => f_re,
			data_out => tx_data,
			we => f_we,
			data_in => data,
			empty => f_empty,
			full => f_full
		);

		
	ready <= not f_full;

	fifo_write_proc : process
	begin
		wait until rising_edge(clk);
		f_we <= '0';
		if (f_full= '0' and we = '1') then
			f_we <= '1';
		end if;
	end process;

	fifo_read_proc : process
	begin
		wait until rising_edge(clk);
		f_re <= '0';
		tx_start <= '0';
		cansend <= '0';
		if (f_empty = '0' and tx_busy = '0' and cansend = '0') then
			f_re <= '1';
			cansend <= '1';
		end if;
		if (cansend = '1') then		
			tx_start <= '1';
		end if;
	end process;
	
end behavioural;