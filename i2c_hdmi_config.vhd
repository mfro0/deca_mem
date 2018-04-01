library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_hdmi_config is
    generic
    (
        CLK_FREQUENCY       : integer;
        I2C_FREQUENCY       : integer
    );
    port
    (
        clk                 : in std_logic;
        reset_n             : in std_logic;
        
        i2c_sclk            : inout std_logic;
        i2c_sdat            : inout std_logic;
        hdmi_tx_int         : in std_logic;
        
        -- debug
        ack_error           : out std_logic;
        reset_button_n      : in std_logic
    );
end entity i2c_hdmi_config;

architecture rtl of i2c_hdmi_config is
    signal i2c_ena          : std_logic := '0';
    signal i2c_busy         : std_logic := '0';
    signal i2c_addr         : std_logic_vector(6 downto 0);
    signal i2c_rw           : std_logic := '0';
    signal i2c_data_rd      : std_logic_vector(7 downto 0);
    signal i2c_data_wr      : std_logic_vector(7 downto 0);
    signal i2c_ack_err      : std_logic := '0';

    signal lut_index        : natural;

    type lut_data_type is array(natural range <>) of unsigned(7 downto 0);
    constant lut_data       : lut_data_type :=
    (
        x"98", x"03",          -- must be set to 0x03 for proper operation
        x"01", x"00",          -- set 'n' value at 6144
        x"02", x"18",          -- set 'n' value at 6144
        x"03", x"00",          -- set 'n' value at 6144
        x"14", x"70",          -- set ch count in the channel status to 8
        x"15", x"20",          -- input 444 (RGB or YcrCb) with separate syncs, 48 kHz fs
        x"16", x"30",          -- output format 444, 24 bit input
        x"18", x"46",          -- disable CSC
        x"40", x"80",          -- general control packet enable
        x"41", x"10",          -- power down control
        x"49", x"a8",          -- set dither mode - 12-to-10 bit
        x"55", x"10",          -- set RGB in AVI infoframe
        x"56", x"08",          -- set active format aspect
        x"96", x"f6",          -- set interrupt
        x"73", x"07",          -- info frame ch count to 8
        x"76", x"1f",          -- set speaker allocation for 8 channels
        x"98", x"03",          -- must be set to 0x03 for proper operation
        x"99", x"02",          -- must be set to default value
        x"9a", x"e0",          -- must be set to 0b1110000
        x"9c", x"30",          -- PLL filter R1 value
        x"9d", x"61",          -- set clock divide
        x"a2", x"a4",          -- must be set to 0xa4 for proper operation
        x"a3", x"a4",          -- must be set to 0xa4 for proper operation
        x"a5", x"04",          -- must be set to default value
        x"ab", x"40",          -- must be set to default value
        x"af", x"16",          -- select HDMI mode
        x"ba", x"60",          -- no clock delay
        x"d1", x"ff",          -- must be set to default value
        x"de", x"10",          -- must be set to default value
        x"e4", x"60",          -- must be set to default value
        x"fa", x"7d",          -- number of times to look for good phase
        x"98", x"03"
    );

    type config_setup_type is (STATE0, STATE1, STATE2);
    signal state                : config_setup_type := STATE0;
    
    signal my_reset_n           : std_logic;
begin
    my_reset_n <= reset_n and reset_button_n;
    
    p_i2c_send_data : process(all)
    begin
        if not my_reset_n then
            lut_index <= lut_data'low;
            state <= STATE0;
            i2c_ena <= '0';
        elsif rising_edge(clk) then
            if lut_index <= lut_data'high then
                case state is
                    when STATE0 =>
                        i2c_ena <= '1';
                        i2c_addr <= 7x"72";
                        i2c_rw <= '0';                      -- write
                        i2c_data_wr <= std_logic_vector(lut_data(lut_index));
                        lut_index <= lut_index + 1;
                        state <= STATE1;
                        
                     when STATE1 =>
                        -- wait until busy gets asserted
                        if not i2c_busy then
                            state <= STATE1;
                        else
                            state <= STATE2;
                        end if;
                    
                    when STATE2 =>
                        if not i2c_busy then
                            i2c_data_wr <= std_logic_vector(lut_data(lut_index));
                            lut_index <= lut_index + 1;
                            state <= STATE1;
                        end if;
                        
                end case;
            else
                i2c_ena <= '0';
            end if;
        end if;
    end process p_i2c_send_data;
    
    ack_error <= i2c_ack_err;

    i_i2c_master : entity work.i2c_master
        generic map
        (
            CLK_FREQUENCY   => CLK_FREQUENCY,           --  input clock speed from user logic in Hz
            I2C_FREQUENCY   => I2C_FREQUENCY            --  speed the i2c bus (scl) will run at in Hz
        )
        port map
        (
            clk             => clk,
            reset_n         => my_reset_n,
            ena             => i2c_ena,
            busy            => i2c_busy,
            addr            => i2c_addr,
            rw              => i2c_rw,
            data_wr         => i2c_data_wr,
            data_rd         => i2c_data_rd,
            ack_error       => i2c_ack_err,
            sda             => i2c_sdat,
            scl             => i2c_sclk
        );
end architecture rtl;
