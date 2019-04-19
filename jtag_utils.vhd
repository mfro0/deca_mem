library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

package jtag_utils is
    function to_string(value : std_ulogic_vector) return string;
    function to_string(value : natural) return string;
    function to_string(value : unsigned) return string;
    
    function to_hstring(value  : std_ulogic_vector) return string;
    function to_hstring(value : natural) return string;
    function to_hstring(value : unsigned) return string;
end package jtag_utils;


package body jtag_utils is
    function to_string(value : std_ulogic_vector) return string is
        constant RESULT_LENGTH  : natural := (value'length + 2) / 3;
        variable result         : string(1 to RESULT_LENGTH);
        variable v              : integer := to_integer(unsigned(value));
    begin
        for i in 0 to RESULT_LENGTH - 1 loop
            result(RESULT_LENGTH - i) := character'val((v mod 10) + character'pos('0'));
            v := v / 10;
        end loop;
        
        return result;
    end function to_string;
    
    function to_string(value : natural) return string is
        constant WIDTH          : integer := integer(ceil(log2(real(value'high))));
        variable uns            : unsigned(WIDTH - 1 downto 0) := (others => '0');
    begin
        uns := to_unsigned(value, uns'length);
        return to_string(std_ulogic_vector(uns));
    end function to_string;
    
    function to_string(value : unsigned) return string is
    begin
        return to_string(std_ulogic_vector(value));
    end function to_string;
    
    -- stolen from VHDL 2008 ieee original
    function to_hstring(value  : std_ulogic_vector) return string is
        constant RESULT_LENGTH  : natural := (value'length + 3) / 4;
        variable pad            : std_ulogic_vector(1 to result_length * 4 - value'length);
        variable padded_value   : std_ulogic_vector(1 to result_length * 4);
        variable result         : string(1 to result_length);
        variable quad           : std_ulogic_vector(1 to 4);
    begin
        if value (value'left) = 'Z' then
            pad := (others => 'Z');
        else
            pad := (others => '0');
        end if;
        padded_value := pad & value;
        for i in 1 to RESULT_LENGTH loop
            quad := To_X01Z(padded_value(4 * i - 3 to 4 * i));
            case quad is
                when x"0"   => result(i) := '0';
                when x"1"   => result(i) := '1';
                when x"2"   => result(i) := '2';
                when x"3"   => result(i) := '3';
                when x"4"   => result(i) := '4';
                when x"5"   => result(i) := '5';
                when x"6"   => result(i) := '6';
                when x"7"   => result(i) := '7';
                when x"8"   => result(i) := '8';
                when x"9"   => result(i) := '9';
                when x"A"   => result(i) := 'A';
                when x"B"   => result(i) := 'B';
                when x"C"   => result(i) := 'C';
                when x"D"   => result(i) := 'D';
                when x"E"   => result(i) := 'E';
                when x"F"   => result(i) := 'F';
                when "ZZZZ" => result(i) := 'Z';
                when others => result(i) := 'X';
            end case;
        end loop;
        return result;
    end function to_hstring;

    function to_hstring(value : natural) return string is
        constant WIDTH          : integer := integer(ceil(log2(real(value'high))));
        variable uns            : unsigned(WIDTH - 1 downto 0) := (others => '0');
    begin
        uns := to_unsigned(value, uns'length);
        return to_hstring(std_ulogic_vector(uns));
    end function to_hstring;
    
    function to_hstring(value : unsigned) return string is
    begin
        return to_hstring(std_ulogic_vector(value));
    end function to_hstring;
end package body jtag_utils;