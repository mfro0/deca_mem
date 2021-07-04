library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package common is

	constant UART_ACK : std_logic_vector(7 downto 0) := "00000110";
	constant UART_NAK : std_logic_vector(7 downto 0) := "00010101";
	constant UART_F : std_logic_vector(7 downto 0) := "01000110"; -- F
	constant UART_P : std_logic_vector(7 downto 0) := "01010000"; -- P
	constant UART_R : std_logic_vector(7 downto 0) := "01010010"; -- R
	constant UART_W : std_logic_vector(7 downto 0) := "01010111"; -- W
	constant UART_QUESTION : std_logic_vector(7 downto 0) := "00111111"; -- ?
	
	constant CMD_PUTCHAR : std_logic_vector(2 downto 0) := "001";
	constant CMD_FILLSCREEN : std_logic_vector(2 downto 0) := "010";
	
	
end common;