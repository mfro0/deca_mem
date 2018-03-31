library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_hdmi_config is
    generic
    (
        CLK_FREQ            : integer := 50000000;      -- 50 MHz
        I2C_FREQ            : integer := 20000          -- 20 KHz
    );
    port
    (
        iclk                : in std_ulogic;
        reset_n             : in std_ulogic;
        i2c_sclk            : inout std_ulogic;
        i2c_sdat            : inout std_logic;
        hdmi_tx_int         : in std_ulogic
    );
end entity i2c_hdmi_config;

architecture rtl of i2c_hdmi_config is
    signal i2c_ena          : std_ulogic;
    signal i2c_busy         : std_ulogic;
    signal i2c_addr         : std_logic_vector(6 downto 0);
    signal i2c_rw           : std_ulogic;
    signal i2c_data_rd      : std_logic_vector(7 downto 0);
    signal i2c_data_wr      : std_logic_vector(7 downto 0);
    signal i2c_ack_err      : std_ulogic;
    signal i2c_ctrl_clk     : std_ulogic;

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
    
begin
    i_i2c_master : entity work.i2c_master
        port map
        (
            clk             => iclk,
            reset_n         => reset_n,
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
    
    
    -- configuration control
    
    p_config : process(all)
        type config_setup_type is (STATE0, STATE1, STATE2);
        variable config_status   : config_setup_type;
    begin
        if not reset_n then
            lut_index <= lut_data'low;
            config_status := STATE0;
            i2c_ena <= '0';
        elsif rising_edge(iclk) then
            if lut_index < lut_data'high then
                case config_status is
                    when STATE0 =>
                        i2c_addr <= 7x"72";
                        i2c_rw <= '1';
                        i2c_data_wr <= std_logic_vector(lut_data(lut_index));
                        i2c_ena <= '1';
                        config_status := STATE1;
                    
                    when STATE1 =>
                        if not i2c_busy then            -- i2c controller isn't busy
                            config_status := STATE2;    -- then go ahead
                        else
                            config_status := STATE1;    -- else wait for a new transfer
                        end if;
                        
                    when STATE2 =>                          
                        lut_index <= lut_index + 1;
                        config_status := STATE0;
                    when others =>
                        null;
                end case;
            else
                if not HDMI_TX_INT then
                    lut_index <= 0;
                end if;
            end if;
        end if;
    end process p_config;
end architecture rtl;
