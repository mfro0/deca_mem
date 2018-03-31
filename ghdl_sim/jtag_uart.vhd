library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity jtag_uart is
    port
    (
        clk      : in   std_ulogic;
        rx_data  : out  std_ulogic_vector(7 downto 0);
        rx_busy  : out  std_ulogic;
        tx_data  : in   std_ulogic_vector(7 downto 0);
        tx_start : in   std_ulogic;
        tx_busy  : out  std_ulogic
     );
end entity jtag_uart;

architecture rtl of jtag_uart is
    component alt_jtag_atlantic
        generic
        (
            INSTANCE_ID                 : integer := 0;
            LOG2_RXFIFO_DEPTH           : integer := 3;
            LOG2_TXFIFO_DEPTH           : integer := 3;
            SLD_AUTO_INSTANCE_INDEX     : string := "YES"
        );
        port
        (
            clk                         : in std_ulogic;
            rst_n                       : in std_ulogic;
            r_dat                       : in std_ulogic_vector(7 downto 0);     -- data from FPGA
            r_val                       : in std_ulogic;                        -- data valid
            r_ena                       : out std_ulogic;                       -- can write (next) cycle or FIFO not full
            t_dat                       : out std_ulogic_vector(7 downto 0);    -- data to FPGA
            t_dav                       : in std_ulogic;                        -- ready to receive more data
            t_ena                       : out std_ulogic;                       -- tx data valid
            t_pause                     : out std_ulogic
        );
    end component alt_jtag_atlantic;

    signal r_dat                        : std_ulogic_vector(7 downto 0);
    signal r_val                        : std_ulogic;
    signal r_ena                        : std_ulogic;
    signal t_dat                        : std_ulogic_vector(7 downto 0);
    signal t_dav                        : std_ulogic;
    signal t_ena                        : std_ulogic;
    signal t_pause                      : std_ulogic;
    
    signal is_full_reg                  : std_ulogic;
    signal data_reg                     : std_ulogic_vector(7 downto 0);
    
    signal cnt                          : unsigned(24 downto 0);
begin
    i_jtag_uart : component alt_jtag_atlantic
        generic map
        (
            INSTANCE_ID                 => 0,
            LOG2_RXFIFO_DEPTH           => 3,
            LOG2_TXFIFO_DEPTH           => 3,
            SLD_AUTO_INSTANCE_INDEX     => "YES"
        )
        port map
        (
            clk                         => clk,
            rst_n                       => '1',
            r_dat                       => r_dat,
            r_val                       => r_val,
            r_ena                       => r_ena,
            t_dat                       => t_dat,
            t_dav                       => t_dav,
            t_ena                       => t_ena,
            t_pause                     => t_pause
        );

    process(clk)
    begin
        if not is_full_reg then
            if t_ena then
                data_reg <= t_dat;
                is_full_reg <= '1';
            end if;
        else
            if r_ena then
                is_full_reg <= '0';
            end if;
        end if;
    end process;

    t_dav <= not is_full_reg and not t_ena;
    r_val <= is_full_reg;
    r_dat <= data_reg;
end architecture rtl;
