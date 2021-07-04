-- Copyright (C) 2016  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel MegaCore Function License Agreement, or other 
-- applicable license agreement, including, without limitation, 
-- that your use is for the sole purpose of programming logic 
-- devices manufactured by Intel and sold by Intel or its 
-- authorized distributors.  Please refer to the applicable 
-- agreement for further details.

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
library altera;
use altera.altera_syn_attributes.all;
use work.common.all;

entity sdcard_test001 is
	port
	(
-- {ALTERA_IO_BEGIN} DO NOT REMOVE THIS LINE!
		clock_50 : in std_logic;
		buttons : in std_logic_vector(1 downto 0);
		leds : out std_logic_vector(7 downto 0);
		TXD: out std_logic;
		RXD : in std_logic;
		sdc_sck : out std_logic;
		sdc_cmd : inout std_logic;
		sdc_dat0 : inout std_logic;
		sdc_dat1 : inout std_logic;
		sdc_dat2 : inout std_logic;
		sdc_dat3 : inout std_logic;
		sdc_cd : in std_logic
-- {ALTERA_IO_END} DO NOT REMOVE THIS LINE!
	);

-- {ALTERA_ATTRIBUTE_BEGIN} DO NOT REMOVE THIS LINE!
-- {ALTERA_ATTRIBUTE_END} DO NOT REMOVE THIS LINE!
end sdcard_test001;

architecture ppl_type of sdcard_test001 is

-- {ALTERA_COMPONENTS_BEGIN} DO NOT REMOVE THIS LINE!
	component pll0 IS
		PORT
		(
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			locked		: OUT STD_LOGIC 
		);
	END component pll0;
	
	component sdcard_controller is
		port (
			clock		: in  std_logic;
			reset    : in  std_logic;
			sck		: out std_logic 		:= '0';
			cmd      : inout  std_logic   := '1';
			dat0     : inout  std_logic   := '1';
			dat1     : inout  std_logic  	:= '1';
			dat2     : inout  std_logic   := '1';
			dat3     : inout  std_logic 	:= '1';
			ready		: out std_logic := '0';
			read_addr : in std_logic_vector(31 downto 0);
			read_enable : in std_logic;
			data		: out std_logic_vector(7 downto 0) := (others => '0');
			data_ready : out std_logic := '0';
			debug_cmd_timeout : out std_logic := '0';
			debug_data_timeout : out std_logic := '0';
			debug_crc_error : out std_logic := '0';
			debug_card_error : out std_logic := '0'
		);
	end component sdcard_controller;

	component uart_transmitter is
		generic(
			clock_speed : integer := 50000000;
			baud : integer := 57600
		);
		port(
			clk : in std_logic;
			we : in std_logic;
			ready : out std_logic := '0';
			data : in std_logic_vector(7 downto 0);
			tx_line : out std_logic := '1'
		);
	end component uart_transmitter;
	
	component uart_receiver is
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
	end component uart_receiver;
	
	component ram1024 IS
		PORT
		(
			clock		: IN STD_LOGIC  := '1';
			data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			rdaddress		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
			wraddress		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
			wren		: IN STD_LOGIC  := '0';
			q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	END component ram1024;
-- {ALTERA_COMPONENTS_END} DO NOT REMOVE THIS LINE!
	signal pll_locked : std_logic;
	signal clock_main : std_logic := '0';

	signal sig_buttons_n : std_logic_vector(1 downto 0) := "11";
	signal sig_buttons_n_sync : std_logic_vector(1 downto 0) := "11";
	
	signal cd_debounce : std_logic_vector(3 downto 0) := (others => '0');
	
	signal sdc_reset : std_logic := '0';
	signal sdc_ready : std_logic := '0';
	signal sdc_data_ready : std_logic := '0';
	signal sdc_data : std_logic_vector(7 downto 0) := (others => '0');
	signal sdc_read_addr : std_logic_vector(31 downto 0) := (others => '0');
	signal sdc_read_enable : std_logic := '0';

-- UART
	signal rx_data : std_logic_vector(7 downto 0) := (others => '0');
	signal rx_ready : std_logic;
	signal rx_re: std_logic;

	type tuart_receiver_state is (uart_idle, uart_wait, uart_read);
	signal uart_receiver_state : tuart_receiver_state := uart_idle;	
		
	signal uart_data_received : std_logic := '0';
	signal uart_data : std_logic_vector(7 downto 0) := (others => '0');
	
	type tuart_handler_state is (uart_handler_idle, uart_handler_get_param, uart_handler_wait);
	signal uart_handler_state : tuart_handler_state := uart_handler_idle;	
	signal uart_param_counter : natural range 0 to 255 := 0;

	signal param_addr : std_logic_vector(31 downto 0) := (others => '0');
	
	signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
	signal tx_we : std_logic := '0';
	signal tx_ready : std_logic;	

	signal readCounter : natural := 0;
	signal writeCounter : natural := 0;
	signal ram_rd_addr : std_logic_vector(9 downto 0);
	signal ram_wr_addr : std_logic_vector(9 downto 0);
	signal ram_we : std_logic := '0';
	
	type TRAMtoUARTstate is (ramtouart_idle, ramtouart_tx_start, ramtouart_tx_wait, ramtouart_tx_end);
	signal ramtouartstate : TRAMtoUARTstate := ramtouart_idle;
	
begin
-- {ALTERA_INSTANTIATION_BEGIN} DO NOT REMOVE THIS LINE!
    sdcard_controllers_inst : sdcard_controller  port map (
			clock		=> clock_main,     
			reset    => sdc_reset or (not pll_locked),          
			sck      => sdc_sck,     
			cmd      => sdc_cmd,    
			dat0     => sdc_dat0,   
			dat1     => sdc_dat1,       
			dat2   	=> sdc_dat2,  
			dat3 		=> sdc_dat3,
			ready		=> sdc_ready,
			read_addr => sdc_read_addr,
			read_enable => sdc_read_enable,
			data => sdc_data,
			data_ready => sdc_data_ready,
			debug_cmd_timeout => leds(4),
			debug_data_timeout => leds(6),
			debug_crc_error => leds(5),
			debug_card_error => leds(7)
	  );

	uart_tx_inst : uart_transmitter generic map( clock_speed => 100000000, baud => 115200 )
		port map(
		clk => clock_main,
		we => tx_we,
		ready => tx_ready,
		data => tx_data,
		tx_line => TXD
	);
	
	uart_rx_inst : uart_receiver generic map( clock_speed => 100000000, baud => 115200 )
		port map(
		clk => clock_main,
		re => rx_re,
		ready => rx_ready,
		data => rx_data,
		rx_line => RXD
	);

	ram1024_inst : ram1024 PORT MAP (
			clock	 => clock_main,
			data	 => sdc_data,
			rdaddress	 => ram_rd_addr,
			wraddress	 => ram_wr_addr,
			wren	 => ram_we,
			q	 => tx_data
	);
-- {ALTERA_INSTANTIATION_END} DO NOT REMOVE THIS LINE!
	
-- PLL to get the 100MHz operating frequency
	pll0_inst : pll0 PORT MAP (
		inclk0	 => clock_50,
		c0	 => clock_main,
		locked	 => pll_locked
	);	
	
	leds(0) <= sdc_cd;
	leds(1) <= sdc_ready;
	leds(2) <= sdc_data_ready;
	leds(3) <= '0';
	
	-- card detect, my SD CARD breakout board has an extra CardDetect pin which is shorted to ground when no card is present else it is floating, I added a pull-up resistor to it
	process
	begin
		wait until rising_edge(clock_main);
		if (sig_buttons_n(0) = '0') then
			cd_debounce <= (others => '0');
			sdc_reset <= '1';
		else
			if (cd_debounce /= "1111") then
				sdc_reset <= '1';
			else
				sdc_reset <= '0';
			end if;
			cd_debounce <= cd_debounce(2 downto 0) & sdc_cd;
		end if;
	end process;

-- buttons	
	process
	begin
		wait until rising_edge(clock_main);
		sig_buttons_n_sync <= buttons;
		sig_buttons_n <= sig_buttons_n_sync;
	end process;

-- store data from sdcard in the ram	
	process
	begin
		wait until rising_edge(clock_main);
		if (sdc_reset = '1') then
			writeCounter <= 0;
			ram_we <= '0';
			ram_wr_addr <= (others => '0');
		else
			ram_we <= '0';
			if ((sdc_data_ready = '1') and (writeCounter >= readCounter)) then
				ram_wr_addr <= std_logic_vector(to_unsigned(writeCounter, 10));
				ram_we <= '1';
				if (writeCounter < 1023) then
					writeCounter <= writeCounter + 1;
				else
					writeCounter <= 0;
				end if;
			end if;
		end if;
	end process;

-- read data from ram and send via uart
	process
	begin
		wait until rising_edge(clock_main);
		if (sdc_reset = '1') then
			readCounter <= 0;
			ram_rd_addr <= (others => '0');
			tx_we <= '0';
			ramtouartstate <= ramtouart_idle;
		else
			tx_we <= '0';
			case ramtouartstate is 
				when ramtouart_idle =>
					if (writeCounter /= readCounter) then
						ram_rd_addr <= std_logic_vector(to_unsigned(readCounter, 10));
						if (readCounter < 1023) then
							readCounter <= readCounter + 1;
						else
							readCounter <= 0;
						end if;						
						ramtouartstate <= ramtouart_tx_start;
					end if;
				
				when ramtouart_tx_start =>
					if (tx_ready = '1') then
						tx_we <= '1';
						ramtouartstate <= ramtouart_tx_wait;
					end if;
				
				when ramtouart_tx_wait =>
					ramtouartstate <= ramtouart_tx_end;
					
				when ramtouart_tx_end =>
					ramtouartstate <= ramtouart_idle;
					
				when others =>
					ramtouartstate <= ramtouart_idle;
					
			end case;
		end if;
	end process;
	
-- UART receiver	
	process
	begin
		wait until rising_edge(clock_main);
		rx_re <= '0';
		uart_data_received <= '0';
		case uart_receiver_state is
			when uart_idle =>
				if ((rx_ready = '1') and ((uart_handler_state = uart_handler_idle) or (uart_handler_state = uart_handler_get_param))) then 
					rx_re <= '1';
					uart_receiver_state <= uart_wait;
				end if;

			when uart_wait =>
				uart_receiver_state <= uart_read;	
		
			when uart_read =>
				uart_data <= rx_data;
				uart_data_received <= '1';
				uart_receiver_state <= uart_idle;		

			when others =>
				uart_receiver_state <= uart_idle;		
		end case;		
	end process;	

-- UART data handler	
	process
	begin
		wait until rising_edge(clock_main);
		sdc_read_enable <= '0';
		case uart_handler_state is		
			when uart_handler_idle =>
				if ((uart_data_received = '1') and (sdc_ready = '1') and (readCounter = writeCounter)) then
					case uart_data is
						when UART_R =>
							uart_param_counter <= 0;
							param_addr <= (others => '0');
							uart_handler_state <= uart_handler_get_param;
							
						when others =>
						
					end case;
				end if;
			
			when uart_handler_get_param =>
				if (uart_param_counter < 4) then
					if (uart_data_received = '1') then
						param_addr <= param_addr(23 downto 0) & uart_data;
						uart_param_counter <= uart_param_counter + 1;
					end if;
				else
					sdc_read_addr <= param_addr;
					sdc_read_enable <= '1';
					uart_handler_state <= uart_handler_wait;
				end if;
			
			when uart_handler_wait =>
				uart_handler_state <= uart_handler_idle;
			
			when others => 
				uart_handler_state <= uart_handler_idle;
				
		end case;
	end process;
	
end;
