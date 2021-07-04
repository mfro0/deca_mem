library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
-- v.2.0
entity sdcard_controller is
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
end entity sdcard_controller;

architecture rtl of sdcard_controller is

	component crc7 is
		port(
			clk : in std_logic;
			reset : in std_logic;
			enable : in std_logic;
			input : in std_logic;
			crc : out std_logic_vector(6 downto 0)
		);
	end component crc7;
	
--	signal crc_r_enable : std_logic := '0';
--	signal crc_r_reset : std_logic := '0';
--	signal crc_r_output : std_logic_vector(6 downto 0) := (others => '0');
--	signal crc_r_input : std_logic := '0';
--	
--	signal crc_s_enable : std_logic := '0';
--	signal crc_s_reset : std_logic := '0';
--	signal crc_s_input : std_logic := '0';
--	signal crc_s_output : std_logic_vector(6 downto 0) := (others => '0');
	
	signal crc_enable : std_logic := '0';
	signal crc_reset : std_logic := '0';
	signal crc_input : std_logic := '0';
	signal crc_output : std_logic_vector(6 downto 0) := (others => '0');

	constant CLOCK_DIV_INIT : natural range 0 to 124 := 123; -- we assume clock is 100MHz and we want a card_clock of ~400KHz so we invert the card_clock signal every 125 clocks
	signal clock_div_counter :natural range 0 to CLOCK_DIV_INIT := 0;
	signal card_clock : std_logic := '0';
	signal toggle_clock : std_logic := '0';
	signal clockstate :std_logic_vector(1 downto 0) := (others => '0');
	signal clock_enable : std_logic_vector(1 downto 0) := "00";
	
	type Tcontrollerstate is (card_inserted, card_initialization, card_ready, card_start_read_data, card_read_data, card_error);
	signal controllerstate : Tcontrollerstate := card_inserted;
	
	Type Tcardinitstate is (card_init_rst, card_init_sic, card_init_asc, card_init_ini, card_init_check_ready_cid, card_init_wait8, card_init_cid_rca, card_init_rca_csd, card_init_csd_switch_clock, card_init_switch_clock_wait_begin, card_init_switch_clock_wait_end, card_init_transfermode, card_init_asc_with_rca, card_init_disable_pullup, card_init_buswidth, card_init_blocklength, card_init_finished);
	signal cardinitstate : Tcardinitstate := card_init_rst;
	
	signal counter0 : natural range 0 to 255 := 0;
	signal counter1 : natural range 0 to 255 := 0;
	signal counter3 : natural range 0 to 65535 := 0;

	constant CMD0 : std_logic_vector(39 downto 0)   := "01"&"000000"&"00000000"&"00000000"&"00000000"&"00000000";
	constant CMD8 : std_logic_vector(39 downto 0)   := "01"&"001000"&"00000000"&"00000000"&"00000001"&"10101010";
	constant RESP8 : std_logic_vector(47 downto 0)  := "00"&"001000"&"00000000"&"00000000"&"00000001"&"10101010"&"0001001"&"1";
	constant CMD55 : std_logic_vector(39 downto 0)  := "01"&"110111"&"00000000"&"00000000"&"00000000"&"00000000";
	constant RESP55 : std_logic_vector(7 downto 0)  := "00"&"110111";
	constant CMD41 : std_logic_vector(39 downto 0)  := "01"&"101001"&"01000000"&"00010000"&"00000000"&"00000000";
	constant CMD2 : std_logic_vector(39 downto 0)   := "01"&"000010"&"00000000"&"00000000"&"00000000"&"00000000";
	constant CMD3 : std_logic_vector(39 downto 0)   := "01"&"000011"&"00000000"&"00000000"&"00000000"&"00000000";
	constant CMD9 : std_logic_vector(7 downto 0)    := "01"&"001001";
	constant CMD7 : std_logic_vector(7 downto 0)    := "01"&"000111";
	constant CMD42 : std_logic_vector(7 downto 0)   := "01"&"101010";
	constant CMD6 : std_logic_vector(7 downto 0)    := "01"&"000110";
	constant CMD16 : std_logic_vector(39 downto 0)  := "01"&"010000"&"00000000"&"00000000"&"00000010"&"00000000";
	constant CMD17 : std_logic_vector(7 downto 0)   := "01"&"010001";

	type Tcardcommandstate is (card_command_idle, card_send_start, card_send_run, card_send_wait8, card_prep_response, card_await_response, card_get_response, card_get_response_long, card_response_error, card_command_finished);
	signal cardcommandstate :Tcardcommandstate := card_command_idle;
	
	signal responsetype : std_logic_vector(1 downto 0) := "00";
	signal sendcommand : std_logic := '0';
	signal command : std_logic_vector(47 downto 0) := (others => '0');
	signal nextcommand : std_logic_vector(47 downto 0) := (others => '0');
	signal response : std_logic_vector(47 downto 0) := (others => '0');
	signal responselong : std_logic_vector(135 downto 0) := (others => '0');
	signal currentcommand : std_logic_vector(5 downto 0):= (others => '0');
	
	type Tdatastate is (data_idle, data_await, data_timeout, data_readh, data_readl, data_avail, data_finished);
	signal datastate : Tdatastate := data_idle;

	signal data_byte : std_logic_vector(7 downto 0) := (others => '0');
	signal data_hl : std_logic := '0';
	
	signal is_high_capacity : std_logic := '0';
	signal rca :std_logic_vector(15 downto 0) := (others => '0');
-- at this point we fech CID from the card but we never use it....
	signal cid :std_logic_vector(127 downto 0) := (others => '0');
-- at this point we fech CSD from the card but we only need 1 or 2 bits of it...
	signal csd :std_logic_vector(127 downto 0) := (others => '0');
	
begin
-- sd card clock
	sck <= card_clock;
---- CRC7 calculator for command
--	cmd_receive_crc7 : crc7 port map(
--		clk => clock,
--		reset => crc_r_reset,
--		enable => crc_r_enable,
--		input => crc_r_input,
--		crc => crc_r_output
--	);	
--
---- CRC7 calculator for reponse
--	cmd_send_crc7 : crc7 port map(
--		clk => clock,
--		reset => crc_s_reset,
--		enable => crc_s_enable,
--		input => crc_s_input,
--		crc => crc_s_output
--	);	

-- CRC7 calculator for command and response
	cmd_resp_crc7 : crc7 port map(
		clk => clock,
		reset => crc_reset,
		enable => crc_enable,
		input => crc_input,
		crc => crc_output
	);	
	
-- clock_proc	
	clock_proc: process
	begin
		wait until rising_edge(clock);
			if (reset = '1') then
				clock_div_counter <= 0;
				card_clock <= '0';
				toggle_clock <= '0';
				clockstate <= (others => '0');
			else
				clockstate <= clockstate(0) & card_clock;						
				if (toggle_clock = '1') then
					toggle_clock <= '0';
					card_clock <= not card_clock;
					clock_div_counter <= 0;
				else
					case clock_enable is 
						when "01" =>
							if (clock_div_counter < CLOCK_DIV_INIT) then
								clock_div_counter <= clock_div_counter + 1;
							else
								toggle_clock <= '1';
							end if;
--						as we assume clock is 100MHz we toggle the card_clock every 2 clocks to get the 25MHz						
						when "10" =>
							toggle_clock <= not toggle_clock;
						
						when others =>
							clockstate <= (others => '0');
							card_clock <= '0';
							clock_div_counter <= 0;
							toggle_clock <= '0';
					
					end case;
				end if;
			end if;
	end process;

-- command and response fsm	
	command_response_fsm: process
	begin
		wait until rising_edge(clock);
		if ((reset = '1') or (controllerstate = card_inserted)) then
			cmd <= '1';
--			crc_r_reset <= '1';
--			crc_s_reset <= '1';
--			crc_r_enable <= '0';
--			crc_s_enable <= '0';
--			crc_s_input <= '0';
--			crc_r_input <= '0';
			crc_reset <= '1';
			crc_enable <= '0';
			crc_input <= '0';
			command <= (others => '0');
			response <= (others => '0');
			responselong <= (others => '0');
			counter1 <= 0;
			cardcommandstate <= card_command_idle;
			debug_cmd_timeout <= '0';
			debug_crc_error <= '0';
		else
--			crc_s_enable <= '0';
--			crc_r_enable <= '0';
			crc_enable <= '0';
			case cardcommandstate is
				when card_command_idle =>
					if (sendcommand = '1') then
						command <= nextcommand;
						currentcommand <= nextcommand(45 downto 40);
--						crc_s_reset <= '0';
						crc_reset <= '0';
--						get first command bit into crc going						
--						crc_s_input <= nextcommand(47);
--						crc_s_enable <= '1';
						crc_input <= nextcommand(47);
						crc_enable <= '1';
						cardcommandstate <= card_send_start;
					end if;
					
				when card_send_start =>
--					get second command bit into crc going						
--					crc_s_input <= command(46);
--					crc_s_enable <= '1';
					crc_input <= command(46);
					crc_enable <= '1';
					counter1 <= 0;
					cardcommandstate <= card_send_run;
			
				when card_send_run =>
--					when card_clock is low			
					if (((clockstate = "10") and (clock_enable = "01")) or ((clockstate = "11") and (clock_enable = "10"))) then
						cmd <= command(47);
						command <= command (46 downto 0) & "0";
						if (counter1 < 47) then
							if (counter1 < 38) then
--								get command bit of the remaining 38 into crc going						
--								crc_s_input <= command(45);
--								crc_s_enable <= '1';
								crc_input <= command(45);
								crc_enable <= '1';
							end if;
--							when the last command bit before the crc was send add the crc to the command							
							if (counter1 = 39) then
--								command(47 downto 40) <= crc_s_output & "1";
								command(47 downto 40) <= crc_output & "1";
							end if;
							counter1 <= counter1 + 1;
						else
							if (responsetype = "00") then
								counter1 <= 0;
								cardcommandstate <= card_send_wait8;
							else
--								crc_r_reset <= '0';
								counter1 <= 0;
								debug_cmd_timeout <= '0';
								cardcommandstate <= card_prep_response;
							end if;
						end if;
					end if;
--			wait 8 clocks before the next stage					
				when card_send_wait8 =>
					if (((clockstate = "10") and (clock_enable = "01")) or ((clockstate = "11") and (clock_enable = "10"))) then
						if (counter1 < 7) then
							counter1 <= counter1 + 1;
						else
							cardcommandstate <= card_command_finished;
						end if;
					end if;
--			set cmd tri-state so we can read it in the next stage					
				when card_prep_response =>
					if (((clockstate = "10") and (clock_enable = "01")) or ((clockstate = "11") and (clock_enable = "10"))) then
						crc_reset <= '1';
						cmd <= 'Z';
						cardcommandstate <= card_await_response;
					end if;
--			check for startbit on cmd (low)					
				when card_await_response =>
--					when card_clock is low		
					if (((clockstate = "10") and (clock_enable = "01")) or ((clockstate = "11") and (clock_enable = "10"))) then
						if (cmd = '0') then
							counter1 <= 0;
							debug_cmd_timeout <= '0';
							response <= (others => '0');
							responselong <= (others => '0');
							crc_reset <= '0';
							if (responsetype = "01") then
--								crc_r_input <= '0';
--								crc_r_enable <= '1';
								crc_input <= '0';
								crc_enable <= '1';
								cardcommandstate <= card_get_response;
							else
								cardcommandstate <= card_get_response_long;
							end if;
						else
							if (counter1 < 255) then
								counter1 <= counter1 + 1;
							else
								debug_cmd_timeout <= '1';
								cardcommandstate <= card_response_error;
							end if;
						end if;
					end if;
--			get the response bits of a normal response (48 bits)					
				when card_get_response =>					
--					when card_clock is low		
					if (((clockstate = "10") and (clock_enable = "01")) or ((clockstate = "11") and (clock_enable = "10"))) then
						response <= response(46 downto 0) & cmd;
						if (counter1 < 46) then
							if (counter1 < 39) then
--			latch cmd for crc as on the next main clock when the crc will be calculated cmd already might have been changed, got crc errors when using cmd directly while on high card_clock speed 								
--								crc_r_input <= cmd;
--								crc_r_enable <= '1';
								crc_input <= cmd;
								crc_enable <= '1';
							end if;
							counter1 <= counter1 + 1;
						else
--							if ((crc_r_output /= response(6 downto 0)) and (currentcommand /= "101001")) then
							if ((crc_output /= response(6 downto 0)) and (currentcommand /= "101001")) then
								debug_crc_error <= '1';
								cardcommandstate <= card_response_error;
							else
								cardcommandstate <= card_command_finished;
							end if;
						end if;
					end if;
--			get the response bits of a long response (48 bits)					
				when card_get_response_long =>
--					when card_clock is low			
					if (((clockstate = "10") and (clock_enable = "01")) or ((clockstate = "11") and (clock_enable = "10"))) then
						responselong <= responselong(134 downto 0) & cmd;
						if (counter1 < 134) then
							if ((counter1 > 6) and (counter1 < 127)) then
--			latch cmd for crc as on the next main clock when the crc will be calculated cmd already might have been changed, got crc errors when using cmd directly while on high card_clock speed
--								crc_r_input <= cmd;
--								crc_r_enable <= '1';
								crc_input <= cmd;
								crc_enable <= '1';
							end if;
							counter1 <= counter1 + 1;
						else
--							if ((crc_r_output /= responselong(6 downto 0)) and (currentcommand /= "101001")) then
							if ((crc_output /= responselong(6 downto 0)) and (currentcommand /= "101001")) then
								debug_crc_error <= '1';
								cardcommandstate <= card_response_error;
							else
								cardcommandstate <= card_command_finished;
							end if;
						end if;
					end if;
-- 		we encountered an error during receiving the response				
				when card_response_error =>
--			do nothing we need to be reset				
					
				when card_command_finished =>
--					crc_s_reset <= '1';
--					crc_r_reset <= '1';
					crc_reset <= '1';
					cardcommandstate <= card_command_idle;
				
				when others =>
					cardcommandstate <= card_command_idle;
						
			end case;
		end if;
	end process;

-- data transfer fsm
	data_transfer_fsm : process
	begin
		wait until rising_edge(clock);
		if (reset = '1') then
			data_ready <= '0';
			counter3 <= 0;
			data <= (others => '0');
			dat0 <= '1';
			dat1 <= '1';
			dat2 <= '1';
			dat3 <= '1';
			datastate <= data_idle;
			debug_data_timeout <= '0';
		else
			data_ready <= '0';
			case datastate is
				when data_idle =>
					counter3 <= 0;
					dat0 <= '1';
					dat1 <= '1';
					dat2 <= '1';
					dat3 <= '1';
--			set DAT lines to tri-state so we can read them					
					if (controllerstate = card_read_data) then
						dat0 <= 'Z';
						dat1 <= 'Z';
						dat2 <= 'Z';
						dat3 <= 'Z';
						datastate <= data_await;
					end if;
--			check for start bits (low) on dat0-3 lines					
				when data_await =>
					if (clockstate = "11") then
						if ((dat0 = '0') and (dat1 = '0') and (dat2 = '0') and (dat3 = '0')) then
							debug_data_timeout <= '0';
							counter3 <= 0;
							data_byte <= (others => '0');
							datastate <= data_readh;
						else
--			big timeout here as I don't know how long it takes the card to start the transfer							
							if (counter3 < 65535) then
								counter3 <= counter3 + 1;
							else
								datastate <= data_timeout;
							end if;
						end if;
					end if;
--			an error has occured
				when data_timeout =>
					debug_data_timeout <= '1';
					if (controllerstate = card_inserted) then
						debug_data_timeout <= '0';
						datastate <= data_idle;
					end if;
--			get the upper 4 bits of the data byte				
				when data_readh =>
					if (clockstate = "11") then
						data_byte(7 downto 4) <= dat3 & dat2 & dat1 & dat0;
						datastate <= data_readl;
					end if;
--			get the lower 4 bits of the data byte				
				when data_readl =>
					if (clockstate = "11") then
						data_byte(3 downto 0) <= dat3 & dat2 & dat1 & dat0;
						datastate <= data_avail;
					end if;
--			present the previously received data byte without the CRC, we don't care for it at this time					
				when data_avail =>
					if (counter3 < 512) then
						data <= data_byte;
						data_ready <= '1';
					end if;
					if (counter3 < 513) then
						counter3 <= counter3 + 1;
						datastate <= data_readh;
					else
						datastate <= data_finished;
					end if;
--			blockread is finished				
				when data_finished =>
					datastate <= data_idle;
				
				when others =>
					datastate <= data_idle;
				
			end case;
		end if;
	end process;
	
-- controller fsm	
	controller_fsm : process
	begin
		wait until rising_edge(clock);
		if (reset = '1') then
			counter0 <= 0;
			responsetype <= "00";
			sendcommand <= '0';
			nextcommand <= (others => '0');
			ready <= '0';
			cardinitstate <= card_init_rst;
			controllerstate <= card_inserted;
		else
			sendcommand <= '0';
--			debug_response_ready <= '0';
			case controllerstate is
--			a card was inserted, we want to wait about 80 initialization clocks to go to the next stage
				when card_inserted =>
					clock_enable <= "01";
					if (clockstate = "10") then
						if (counter0 < 80) then
							counter0 <= counter0 + 1;
						else
							cardinitstate <= card_init_rst;
							controllerstate <= card_initialization;
						end if;
					end if;
-- 		a card was inserted an now we start the initialization process				
				when card_initialization =>
					case cardinitstate is
--					send soft reset command (CMD0, no response)
						when card_init_rst =>
							responsetype <= "00";
							nextcommand(47 downto 8) <= CMD0;
							sendcommand <= '1';
							cardinitstate <= card_init_sic;
							
						when card_init_sic =>
--					send voltage range (3.3V)
							if (cardcommandstate = card_command_finished) then
								responsetype <= "01";
								nextcommand(47 downto 8) <= CMD8;
								sendcommand <= '1';	
								cardinitstate <= card_init_asc;							
							elsif(cardcommandstate = card_response_error) then
								controllerstate <= card_error;
							end if;
--					send the next command is an Application Specific Command
						when card_init_asc =>
							if (cardcommandstate = card_command_finished) then
								responsetype <= "01";
								nextcommand(47 downto 8) <= CMD55;
								sendcommand <= '1';	
								cardinitstate <= card_init_ini;
							elsif(cardcommandstate = card_response_error) then
								controllerstate <= card_error;
							end if;
--					send card enter init process
						when card_init_ini =>
							if (cardcommandstate = card_command_finished) then
								if (response(47 downto 40) = RESP55) then
									responsetype <= "01";
									nextcommand(47 downto 8) <= CMD41;
									sendcommand <= '1';	
									cardinitstate <= card_init_check_ready_cid;
								else
									controllerstate <= card_error;
								end if;
							elsif(cardcommandstate = card_response_error) then
								controllerstate <= card_error;
							end if;
--					check if card is ready and request CID
						when card_init_check_ready_cid =>
							if (cardcommandstate = card_command_finished) then
								if ((response(47 downto 39) = "001111111") and (response(7 downto 0) = "11111111")) then
									is_high_capacity <= response(38);
									if (response(28) = '1') then	-- card is ready
										nextcommand(47 downto 8) <= CMD2; -- get long cid csd response
										responsetype <= "10"; -- long response
										sendcommand <= '1';
										cardinitstate <= card_init_cid_rca;
									else
										controllerstate <= card_error;
									end if;								
								else
									counter0 <= 0;
									cardinitstate <= card_init_wait8;
								end if;	
							elsif(cardcommandstate = card_response_error) then
								controllerstate <= card_error;
							end if;							
--					wait 8 clocks before we try next init run
						when card_init_wait8 =>
							if (clockstate = "10") then
								if (counter0 < 7) then
									counter0 <= counter0 + 1;
								else
									responsetype <= "01";
									nextcommand(47 downto 8) <= CMD55;
									sendcommand <= '1';	
									cardinitstate <= card_init_ini;
								end if;
							end if;
--					get CID and send give me your Relative Card Address		
						when card_init_cid_rca =>
							if (cardcommandstate = card_command_finished) then
								if (responselong(135 downto 128) = "00111111") then
									cid <= responselong(127 downto 0);
									responsetype <= "01";
									nextcommand(47 downto 8) <= CMD3;
									sendcommand <= '1';	
									cardinitstate <= card_init_rca_csd;
								else
									controllerstate <= card_error;
								end if;
							elsif(cardcommandstate = card_response_error) then
								controllerstate <= card_error;
							end if;													
--					get RCA and send give me CSD		
						when card_init_rca_csd =>
							if (cardcommandstate = card_command_finished) then
								if ((response(47 downto 40) = "00000011") and (response(23 downto 21) = "000")) then
									rca <= response(39 downto 24);
									nextcommand(47 downto 40) <= CMD9; -- get CSD
									nextcommand(39 downto 8) <= response(39 downto 24) & "0000000000000000"; -- RCA								
									responsetype <= "10";
									sendcommand <= '1';	
									cardinitstate <= card_init_csd_switch_clock;
								else
									controllerstate <= card_error;
								end if;
							elsif(cardcommandstate = card_response_error) then
								controllerstate <= card_error;
							end if;													
--					get CSD and go to switch clock start	
						when card_init_csd_switch_clock =>
							if (cardcommandstate = card_command_finished) then
								if (responselong(135 downto 128) = "00111111") then
									csd <= responselong(127 downto 0);
									if (responselong(127 downto 126) /= "01") then -- we only want csd structure version 2.0
										controllerstate <= card_error;
									else
										counter0 <= 0;
										cardinitstate <= card_init_switch_clock_wait_begin;
									end if;
								else
									controllerstate <= card_error;
								end if;
							elsif(cardcommandstate = card_response_error) then
								controllerstate <= card_error;
							end if;																			
--					wait 80 clocks (I thought it might be a good idea to give the card some time before and after switching the clock speed) and switch clock to high speed	
						when card_init_switch_clock_wait_begin =>
							if (clockstate = "10") then
								if (counter0 < 80) then
									counter0 <= counter0 + 1;
								else
									clock_enable <= "10";
									counter0 <= 0;
									cardinitstate <= card_init_switch_clock_wait_end;
								end if;
							end if;
--					wait 80 clocks after clock has been switched to high speed and send card to transfer mode
						when card_init_switch_clock_wait_end =>
							if (clockstate = "10") then
								if (counter0 < 80) then
									counter0 <= counter0 + 1;
								else
									nextcommand(47 downto 40) <= CMD7; -- set card to transfer mode
									nextcommand(39 downto 8) <= rca & "0000000000000000"; -- RCA
									responsetype <= "01";
									sendcommand <= '1';
									cardinitstate <= card_init_transfermode;
								end if;
							end if;						
--					send the next command is an Application Specific Command + our previously received RCA					
						when card_init_transfermode =>
							if (cardcommandstate = card_command_finished) then
								if ((response(47 downto 40) = "00000111") and (response(27) = '0')) then
									responsetype <= "01";
									nextcommand(47 downto 40) <= CMD55(39 downto 32); -- next command is an Application Specific Command
									nextcommand(39 downto 8) <= rca & "0000000000000000";
									sendcommand <= '1';
									cardinitstate <= card_init_asc_with_rca;
								else
									controllerstate <= card_error;
								end if;
							elsif(cardcommandstate = card_response_error) then
								controllerstate <= card_error;
							end if;																									
--					send disable pullup on DAT3
						when card_init_asc_with_rca =>
							if (cardcommandstate = card_command_finished) then
								if (response(47 downto 40) = RESP55) then
									responsetype <= "01";
									nextcommand(47 downto 40) <= CMD42; -- disable pullup on dat3
									nextcommand(39 downto 8) <= rca & "0000000000000000"; -- RCA + pullup disabled
									sendcommand <= '1';
									cardinitstate <= card_init_disable_pullup;
								else
									controllerstate <= card_error;
								end if;
							elsif(cardcommandstate = card_response_error) then
								controllerstate <= card_error;
							end if;																															
--					send the next command is an Application Specific Command + our previously received RCA					
						when card_init_disable_pullup =>
							if (cardcommandstate = card_command_finished) then
								if ((response(47 downto 40 ) = "00101010") and (response(27) = '0')) then
									responsetype <= "01";
									nextcommand(47 downto 40) <= CMD55(39 downto 32); -- next command is an Application Specific Command
									nextcommand(39 downto 8) <= rca & "0000000000000000";
									sendcommand <= '1';
									cardinitstate <= card_init_buswidth;
								else
									controllerstate <= card_error;
								end if;
							elsif(cardcommandstate = card_response_error) then
								controllerstate <= card_error;
							end if;																																	
--					send set bus width to 4 bit			
						when card_init_buswidth =>
							if (cardcommandstate = card_command_finished) then
								if (response(47 downto 40) = RESP55) then
									responsetype <= "01";
									nextcommand(47 downto 40) <= CMD6; -- set bus width
									nextcommand(39 downto 8) <= rca & "0000000000000010"; -- RCA + bus width 4 bit
									sendcommand <= '1';
									cardinitstate <= card_init_blocklength;
								else
									controllerstate <= card_error;
								end if;
							elsif(cardcommandstate = card_response_error) then
								controllerstate <= card_error;
							end if;																														
--					send set block length to 512 bytes				
						when card_init_blocklength =>
							if (cardcommandstate = card_command_finished) then
								if ((response(47 downto 40 ) = "00000110") and (response(27) = '0')) then
									responsetype <= "01";
									nextcommand(47 downto 8) <= CMD16; -- set block length to 512 byte
									sendcommand <= '1';
									cardinitstate <= card_init_finished;
								else
									controllerstate <= card_error;
								end if;
							elsif(cardcommandstate = card_response_error) then
								controllerstate <= card_error;
							end if;																											
--					we are almost done...						
						when card_init_finished =>
							if (cardcommandstate = card_command_finished) then
								if ((response(47 downto 40 ) = "00010000") and (response(27) = '0')) then
									controllerstate <= card_ready;
								else
									controllerstate <= card_error;
								end if;
							elsif(cardcommandstate = card_response_error) then
--								debug_response <= response;
--								debug_response_ready <= '1';
								controllerstate <= card_error;
							end if;																									
							
						when others =>
							cardinitstate <= card_init_rst;
							
					end case;
					
				when card_ready =>
					ready <= '1';
					if (read_enable = '1') then
						nextcommand(47 downto 40) <= CMD17; -- read single block
						if (is_high_capacity = '1') then
							nextcommand(39 downto 8) <= "000000000" & read_addr(31 downto 9); 
						else
							nextcommand(39 downto 8) <= read_addr(31 downto 9) & "000000000";
						end if;
						responsetype <= "01";
						sendcommand <= '1';
						ready <= '0';
						controllerstate <= card_start_read_data;
					end if;
				
				when card_start_read_data =>
					if (cardcommandstate = card_command_finished) then
						if ((response(47 downto 40 ) = "00010001") and (response(27) = '0')) then
							controllerstate <= card_read_data;
						else
							controllerstate <= card_error;
						end if;
					elsif(cardcommandstate = card_response_error) then
--								debug_response <= response;
--								debug_response_ready <= '1';
						controllerstate <= card_error;
					end if;																					
				
				when card_read_data =>
					if (datastate = data_finished) then
						controllerstate <= card_ready;
					elsif (datastate = data_timeout) then
						controllerstate <= card_error;
					end if;

				when card_error =>
-- do nothing, we need to be reset here
					debug_card_error <= '1';
					if (cardinitstate = card_init_asc) then
						debug_card_error <= '0';
						controllerstate <= card_inserted;
					end if;
					
				when others =>
					controllerstate <= card_inserted;
					
			end case;
		end if;
	end process;
	
end architecture rtl; -- of sdcard_controller
