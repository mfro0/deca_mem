library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity jtag_uart is
    port
    (
        clk             : in std_logic;
        reset_n         : in std_logic; 
        
        rx_data         : out std_logic_vector(7 downto 0);
        rx_data_ready   : out std_logic;
        
        tx_data         : in  std_logic_vector(7 downto 0);
        tx_start        : in  std_logic;
        tx_busy         : out std_logic
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
            clk                         : in std_logic;
            rst_n                       : in std_logic;
            r_dat                       : in std_logic_vector(7 downto 0);      -- data from FPGA
            r_val                       : in std_logic;                         -- data valid
            r_ena                       : out std_logic;                        -- can write (next) cycle or FIFO not full
            t_dat                       : out std_logic_vector(7 downto 0);     -- data to FPGA
            t_dav                       : in std_logic;                         -- ready to receive more data
            t_ena                       : out std_logic;                        -- tx data valid
            t_pause                     : out std_logic
        );
    end component alt_jtag_atlantic;

    signal r_dat                        : std_logic_vector(7 downto 0);
    signal r_val                        : std_logic;
    signal r_ena                        : std_logic;
    signal t_dat                        : std_logic_vector(7 downto 0);
    signal t_dav                        : std_logic;
    signal t_ena                        : std_logic;
    signal t_pause                      : std_logic;
    
    signal is_full_reg                  : std_logic;
    signal data_reg                     : std_logic_vector(7 downto 0);
    
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
            rst_n                       => reset_n,
            r_dat                       => r_dat,
            r_val                       => r_val,
            r_ena                       => r_ena,
            t_dat                       => t_dat,
            t_dav                       => t_dav,
            t_ena                       => t_ena,
            t_pause                     => t_pause
        );

    p_doit : process(all)
    begin
        if not reset_n then
            null;
            
        elsif rising_edge(clk) then
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
        end if;
    end process;

    t_dav <= not is_full_reg and not t_ena;
    r_val <= is_full_reg;
    r_dat <= data_reg;
end architecture rtl;
