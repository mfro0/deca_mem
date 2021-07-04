library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_receiver is
	generic(
		clock_speed : integer := 50000000;
		baud : integer := 9600
	);
	port(
		clk : in std_logic;
		re : in std_logic;
		ready : out std_logic := '0';
		data : out std_logic_vector(7 downto 0);
		rx_line : in std_logic
	);
end uart_receiver;

architecture behavioural of uart_receiver is
	component uart_rx is
		generic(
			clock_speed : integer := 50000000;
			baud : integer := 9600
		);
		port(
			clk : in std_logic;
			busy : out std_logic := '0';
			data : out std_logic_vector(7 downto 0)  := (others => '0');
			rx_line : in std_logic
		);
	end component uart_rx;	

	signal rx_data : std_logic_vector(7 downto 0) := (others => '0');
	signal rx_busy : std_logic := '0';
	signal rx_busy_last : std_logic := '0';
	
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
	
begin
	uart_rx_inst : uart_rx generic map( clock_speed => clock_speed, baud => baud )
		port map(
		clk => clk,
		busy => rx_busy,
		data => rx_data,
		rx_line => rx_line
	);
	
	fifo_inst : fifo generic map( depth => 16, width => 8)
			port map(
			clk => clk,
			re => re,
			data_out => data,
			we => f_we,
			data_in => rx_data,
			empty => f_empty,
			full => f_full
		);
		
	ready <= not f_empty;

	fifo_write_proc : process
	begin
		wait until rising_edge(clk);
		f_we <= '0';
		if (rx_busy = '0' and rx_busy_last = '1' and f_full = '0') then
			f_we <= '1';
		end if;
		rx_busy_last <= rx_busy;
	end process;
	
end behavioural;