library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity i2c_controller is
    port
    (
        clock           : in std_logic;
        i2c_sdat        : inout std_logic;
        i2c_data        : in unsigned(23 downto 0);
        go              : in std_logic;
        reset_n         : in std_logic;
        i2c_end         : out std_logic;
        i2c_ack         : out std_logic;
        i2c_sclk        : out std_logic
    );
end entity i2c_controller;

architecture rtl of i2c_controller is
    signal sdo          : std_logic;
    signal sclk         : std_logic;
    signal sd           : unsigned(23 downto 0);
    signal sd_counter   : integer range 0 to 63;
    signal i2c_ack1,
           i2c_ack2,
           i2c_ack3     : std_logic;
begin
    i2c_sclk <= '1' when sclk = '1' else
                not clock when (sd_counter >= 4 and sd_counter <= 30) else
                '0';
    
    i2c_sdat <= '1' when sdo = '1' else
                'Z';
    
    i2c_ack <= i2c_ack1 or i2c_ack2 or i2c_ack3;
    
    p_i2c_counter : process(all)
    begin
        if not reset_n then
            sd_counter <= 63;
        elsif rising_edge(clock) then
            if go = '0' then
                sd_counter <= 0;
            elsif sd_counter < 63 then
                sd_counter <= sd_counter + 1;
            end if;
        end if;
    end process p_i2c_counter;
    
    p_i2c_doit : process(all)
    begin
        if not reset_n then
            sclk <= '1';
            sdo <= '1';
            i2c_ack1 <= '0';
            i2c_ack2 <= '0';
            i2c_ack3 <= '0';
            i2c_end <= '1';
        elsif rising_edge(clock) then
            case sd_counter is
                when 0 =>
                    i2c_ack1 <= '0';
                    i2c_ack2 <= '0';
                    i2c_ack3 <= '0';
                    i2c_end <= '0';
                    sdo <= '1';
                    sclk <= '1';
                
                -- start 
                
                when 1 =>
                    sd <= i2c_data;
                    sdo <= '0';
                
                when 2 =>
                    sclk <= '0';
                
                -- slave address
                
                when 3 => sdo <= sd(23);
                when 4 => sdo <= sd(22);
                when 5 => sdo <= sd(21);
                when 6 => sdo <= sd(20);
                when 7 => sdo <= sd(19);
                when 8 => sdo <= sd(18);
                when 9 => sdo <= sd(17);
                when 10 => sdo <= sd(16);
                when 11 => sdo <= '1';      -- ack
                
                -- sub address
                
                when 12 =>
                    sdo <= sd(15);
                    i2c_ack1 <= i2c_sdat;
                when 13 => sdo <= sd(14);
                when 14 => sdo <= sd(13);
                when 15 => sdo <= sd(12);
                when 16 => sdo <= sd(11);
                when 17 => sdo <= sd(10);
                when 18 => sdo <= sd(9);
                when 19 => sdo <= sd(8);
                when 20 => sdo <= '1';      -- ack
                
                -- data
                
                when 21 =>
                    sdo <= sd(7);
                    i2c_ack2 <= i2c_sdat;
                
                when 22 => sdo <= sd(6);
                when 23 => sdo <= sd(5);
                when 24 => sdo <= sd(4);
                when 25 => sdo <= sd(3);
                when 26 => sdo <= sd(2);
                when 27 => sdo <= sd(1);
                when 28 => sdo <= sd(0);
                when 29 => sdo <= '1';      -- ack
                
                when 30 =>
                    sdo <= '0';
                    sclk <= '0';
                    i2c_ack3 <= i2c_sdat;
                
                when 31 =>
                    sclk <= '1';
                
                when others =>              -- 32 +
                    sdo <= '1';
                    i2c_end <= '1';
                
            end case;
        end if; 
    end process p_i2c_doit;
end architecture rtl;
