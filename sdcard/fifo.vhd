library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
	generic(
		depth : integer := 16;
		width : integer := 8
	);
	port(
		clk : in std_logic;
--		reset : in std_logic;
		re : in std_logic;
		data_out : out std_logic_vector(width-1 downto 0) := (others => '0');
		we : in std_logic;
		data_in : in std_logic_vector(width-1 downto 0);
		empty : out std_logic := '1';
		full : out std_logic := '0'
	);
end fifo;

architecture behavioural of fifo is
	-- holds the fifo data
	type tmemory is array(0 to depth-1) of std_logic_vector(width-1 downto 0);
	signal memory: tmemory;
	-- read index pointer
	signal r_ptr : natural range 0 to depth-1 := 0;
	-- write index pointer
	signal w_ptr : natural range 0 to depth-1 := 0;
	-- overflow indicator (write index pointer < read index pointer)
	signal ov : std_logic := '0';
	
	signal s_empty : std_logic := '1';
	signal s_full : std_logic := '0';
	
begin

	empty <= s_empty;
	full <= s_full;
	
	process
	begin
		wait until rising_edge(clk);
--		if (we = '1' and s_full = '0') then
--			memory(w_ptr) <= data_in;
--			if (w_ptr < (depth - 1)) then
--				w_ptr <= w_ptr + 1;
--			else
--				w_ptr <= 0;
--				ov <= '1';
--			end if;
--		end if;
--		if (re = '1' and s_empty = '0')then
--			data_out <= memory(r_ptr);
--			if (r_ptr < (depth - 1)) then
--				r_ptr <= r_ptr + 1;
--			else
--				r_ptr <= 0;
--				ov <= '0';
--			end if;
--		end if;		
		if ((we = '1' and re = '0') and (s_full = '0')) then
			memory(w_ptr) <= data_in;
			if (w_ptr < (depth - 1)) then
				w_ptr <= w_ptr + 1;
			else
				w_ptr <= 0;
				ov <= '1';
			end if;
		elsif ((we = '0' and re = '1')  and (s_empty = '0'))then
			data_out <= memory(r_ptr);
			if (r_ptr < (depth - 1)) then
				r_ptr <= r_ptr + 1;
			else
				r_ptr <= 0;
				ov <= '0';
			end if;
		elsif (we = '1' and re = '1') then
			if (s_empty = '1') then
				memory(w_ptr) <= data_in;
				data_out <= data_in;
				if (w_ptr < (depth - 1)) then
					w_ptr <= w_ptr + 1;
				else
					w_ptr <= 0;
					ov <= '1';
				end if;						
				if (r_ptr < (depth - 1)) then
					r_ptr <= r_ptr + 1;
				else
					r_ptr <= 0;
					ov <= '0';
				end if;
			else
				data_out <= memory(r_ptr);
				memory(w_ptr) <= data_in;
				if (r_ptr < (depth - 1)) then
					r_ptr <= r_ptr + 1;
				else
					r_ptr <= 0;
					ov <= '0';
				end if;
				if (w_ptr < (depth - 1)) then
					w_ptr <= w_ptr + 1;
				else
					w_ptr <= 0;
					ov <= '1';
				end if;
			end if;
		end if;
	end process;
	
	process(r_ptr, w_ptr, ov)
	begin
		if (r_ptr = w_ptr) then
			if (ov = '0') then
				s_empty <= '1';
				s_full <= '0';
			else
				s_empty <= '0';
				s_full <= '1';
			end if;
		else
			s_empty <= '0';
			s_full <= '0';
		end if;
	end process;
	
end behavioural;