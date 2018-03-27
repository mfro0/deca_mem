library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity i2c_controller is
    port
    (
        clock           : in std_ulogic;
        i2c_sdat        : inout std_ulogic;
        i2c_data        : in unsigned(23 downto 0);
        go              : in std_ulogic;
        reset_n         : in std_ulogic;
        e_nd            : out std_ulogic;
        ack             : out std_ulogic;
        i2c_sclk        : out std_ulogic
    );
end entity i2c_controller;

architecture rtl of i2c_controller is
    signal sdo          : std_ulogic;
    signal sclk         : std_ulogic;
    signal sd           : unsigned(23 downto 0);
    signal sd_counter   : unsigned(5 downto 0);
    signal ack1,
           ack2,
           ack3         : std_ulogic;
begin
    i2c_sclk <= '1' when sclk = '1' else
                not clock when (sd_counter >= 4 and sd_counter <= 30) else
                '0';
    
    i2c_sdat <= '1' when sdo = '1' else
                'Z';
    
    ack <= ack1 or ack2 or ack3;
    
    p_i2c_counter : process
    begin
        wait until rising_edge(clock);
        if reset_n = '0' then
            sd_counter <= 6b"111111";
        else
            if go = '0' then
                sd_counter <= (others => '0');
            elsif sd_counter < 6b"111111" then
                sd_counter <= sd_counter + 1;
            end if;
        end if;
    end process p_i2c_counter;
    
    p_i2c_doit : process
    begin
        wait until rising_edge(clock);
        if reset_n = '0' then
            sclk <= '1';
            sdo <= '1';
            ack1 <= '0';
            ack2 <= '0';
            ack3 <= '0';
            e_nd <= '1';
        else
            case sd_counter is
                when 6d"0" =>
                    ack1 <= '0';
                    ack2 <= '0';
                    ack3 <= '0';
                    e_nd <= '0';
                    sdo <= '1';
                    sclk <= '1';
                
                when 6d"1" =>
                    sd <= i2c_data;
                    sdo <= '0';
                
                when 6d"2" =>
                    sclk <= '0';
                
                when 6d"3" =>
                    sdo <= sd(23);
                    
                when 6d"4" =>
                    sdo <= sd(22);
                    
                when 6d"5" =>
                    sdo <= sd(21);
                
                when 6d"6" =>
                    sdo <= sd(20);
                
                when 6d"7" =>
                    sdo <= sd(19);

                when 6d"8" =>
                    sdo <= sd(18);
                
                when 6d"9" =>
                    sdo <= sd(17);
                
                when 6d"10" =>
                    sdo <= sd(16);
                    
                when 6d"11" =>
                    sdo <= '1';     -- ack
                
                when 6d"12" =>
                    sdo <= sd(15);
                    ack1 <= i2c_sdat;
                
                when 6d"13" =>
                    sdo <= sd(14);
                
                when 6d"14" =>
                    sdo <= sd(13);
                
                when 6d"15" =>
                    sdo <= sd(12);
                
                when 6d"16" =>
                    sdo <= sd(11);
                
                when 6d"17" =>
                    sdo <= sd(10);
                
                when 6d"18" =>
                    sdo <= sd(9);
                
                when 6d"19" =>
                    sdo <= sd(8);
                
                when 6d"20" =>
                    sdo <= '1';         -- ack
                
                when 6d"21" =>
                    sdo <= sd(7);
                    ack2 <= i2c_sdat;
                
                when 6d"22" =>
                    sdo <= sd(6);
                
                when 6d"23" =>
                    sdo <= sd(5);
                
                when 6d"24" =>
                    sdo <= sd(4);
                
                when 6d"25" =>
                    sdo <= sd(3);
                
                when 6d"26" =>
                    sdo <= sd(2);
                
                when 6d"27" =>
                    sdo <= sd(1);
                
                when 6d"28" =>
                    sdo <= sd(0);
                
                when 6d"29" =>
                    sdo <= '1';         -- ack
                
                when 6d"30" =>
                    sdo <= '0';
                    sclk <= '0';
                    ack3 <= i2c_sdat;
                
                when 6d"31" =>
                    sclk <= '1';
                
                when 6d"32" =>
                    sdo <= '1';
                    e_nd <= '1';
                
                when others =>
                    null;
            end case;
        end if; 
    end process p_i2c_doit;
end architecture rtl;