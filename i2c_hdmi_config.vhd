library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_hdmi_config is
    generic
    (
        CLK_FREQ            : integer := 50000000;      -- 50 MHz
        I2C_FREQ            : integer := 20000;         -- 20 KHz
        LUT_SIZE            : integer := 31     
    );
    port
    (
        iclk                : in std_ulogic;
        reset_n              : in std_ulogic;
        i2c_sclk            : out std_ulogic;
        i2c_sdat            : inout std_logic;
        hdmi_tx_int         : in std_ulogic
    );
end entity i2c_hdmi_config;

architecture rtl of i2c_hdmi_config is
    signal mi2c_clk_div     : unsigned(15 downto 0);
    signal i2c_data        : unsigned(23 downto 0);
    signal mi2c_ctrl_clk    : std_ulogic;
    signal mi2c_go          : std_ulogic;
    signal mi2c_end         : std_ulogic;
    signal mi2c_ack         : std_ulogic;
    signal lut_index        : natural;
    
    type lut_data_type is array(natural range <>) of unsigned(15 downto 0);
    constant lut_data       : lut_data_type :=
    (
        16x"9803",          -- must be set to 0x03 for proper operation
        16x"0100",          -- set 'n' value at 6144
        16x"0218",          -- set 'n' value at 6144
        16x"0300",          -- set 'n' value at 6144
        16x"1470",          -- set ch count in the channel status to 8
        16x"1520",          -- input 444 (RGB or YcrCb) with separate syncs, 48 kHz fs
        16x"1630",          -- output format 444, 24 bit input
        16x"1846",          -- disable CSC
        16x"4080",          -- general control packet enable
        16x"4110",          -- power down control
        16x"49a8",          -- set dither mode - 12-to-10 bit
        16x"5510",          -- set RGB in AVI infoframe
        16x"5608",          -- set active format aspect
        16x"96f6",          -- set interrupt
        16x"7307",          -- info frame ch count to 8
        16x"761f",          -- set speaker allocation for 8 channels
        16x"9803",          -- must be set to 0x03 for proper operation
        16x"9902",          -- must be set to default value
        16x"9ae0",          -- must be set to 0b1110000
        16x"9c30",          -- PLL filter R1 value
        16x"9d61",          -- set clock divide
        16x"a2a4",          -- must be set to 0xa4 for proper operation
        16x"a3a4",          -- must be set to 0xa4 for proper operation
        16x"a504",          -- must be set to default value
        16x"ab40",          -- must be set to default value
        16x"af16",          -- select HDMI mode
        16x"ba60",          -- no clock delay
        16x"d1ff",          -- must be set to default value
        16x"de10",          -- must be set to default value
        16x"e460",          -- must be set to default value
        16x"fa7d",          -- number of times to look for good phase
        16x"9803"
    );
    
begin
    p_control_clock : process
    begin
        report "size of lut_data is " & integer'image(lut_data'low) & " to " & integer'image(lut_data'high) severity note;
        wait until rising_edge(iclk);
        if reset_n = '0' then
            mi2c_ctrl_clk   <= '0';
            mi2c_clk_div    <= (others => '0');
        else
            if mi2c_clk_div < CLK_FREQ / I2C_FREQ then
                mi2c_clk_div <= mi2c_clk_div + 1;
            else
                mi2c_clk_div <= (others => '0');
                mi2c_ctrl_clk <= not mi2c_ctrl_clk;
            end if;
        end if;
    end process p_control_clock;
    
    i_i2c_controller : entity work.i2c_controller
        port map
        (
            clock           => mi2c_ctrl_clk,
            i2c_sclk        => i2c_sclk,
            i2c_sdat        => i2c_sdat,
            i2c_data        => i2c_data,
            go              => mi2c_go,
            e_nd            => mi2c_end,
            ack             => mi2c_ack,
            reset_n         => reset_n
        );
    
    p_config : process
        type config_setup_type is (STATE0, STATE1, STATE2);
        variable config_status   : config_setup_type;
    begin
        wait until rising_edge(mi2c_ctrl_clk);
        
        if not reset_n then
            lut_index <= 0;
            config_status := STATE0;
            mi2c_go <= '0';
        else
            if lut_index < LUT_SIZE then
                case config_status is
                    when STATE0 =>
                        i2c_data <= 8x"72" & lut_data(lut_index);
                        mi2c_go <= '1';
                        config_status := STATE1;
                    
                    when STATE1 =>
                        if mi2c_end then
                            if not mi2c_ack then
                                config_status := STATE2;
                            else
                                config_status := STATE0;
                                mi2c_go <= '0';
                            end if;
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
                else
                    lut_index <= lut_index;
                end if;
            end if;
        end if;
    end process p_config;
end architecture rtl;