library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity jtag_uart is
    generic
    (
        LOG2_RXFIFO_DEPTH               : natural;
        LOG2_TXFIFO_DEPTH               : natural
    );
    port
    (
        clk                             : in std_ulogic;
        reset_n                         : in std_ulogic;

        rx_data                         : out character;    -- received data
        rx_ready                        : out std_ulogic;   -- received data valid
        rx_data_req                     : in std_ulogic;    -- ask for data
        rx_paused                       : out std_ulogic;   -- receive paused

        tx_data                         : in  character;    -- data to send
        tx_start                        : in  std_ulogic;   -- start sending data
        tx_idle                         : out std_ulogic    -- we are not busy sending
     );
end entity jtag_uart;

architecture rtl of jtag_uart is
    component alt_jtag_atlantic
        generic
        (
            INSTANCE_ID                 : integer := 0;
            LOG2_RXFIFO_DEPTH           : integer := 0;
            LOG2_TXFIFO_DEPTH           : integer := 0;
            SLD_AUTO_INSTANCE_INDEX     : string := "YES"
        );
        port
        (
            clk                         : in std_ulogic;
            rst_n                       : in std_ulogic;
            
            r_dat                       : in character;                         -- data to send
            r_val                       : in std_ulogic;                        -- data is valid
            r_ena                       : out std_ulogic;                       -- allow to send data
            
            t_dat                       : out character;                        -- incoming data
            t_dav                       : in std_ulogic;                        -- give us more data
            t_ena                       : out std_ulogic;                       -- received data available
            t_pause                     : out std_ulogic
        );
    end component alt_jtag_atlantic;

begin
    i_jtag_uart : component alt_jtag_atlantic
        generic map
        (
            INSTANCE_ID                 => 0,
            LOG2_RXFIFO_DEPTH           => LOG2_RXFIFO_DEPTH,
            LOG2_TXFIFO_DEPTH           => LOG2_TXFIFO_DEPTH,
            SLD_AUTO_INSTANCE_INDEX     => "YES"
        )
        port map
        (
            clk                         => clk,
            rst_n                       => reset_n,

            -- alt_jtag_atlantic ports have _very_ strange (kind of backwards) names...
            
            -- this is the receiving part of alt_jtag_atlantic, the ports
            -- we actually *send* data to
            r_dat                       => tx_data,
            r_val                       => tx_start,
            r_ena                       => tx_idle,

            -- this is the sending part of alt_jtag_atlantic, i.e. the ports
            -- we receive data from
            t_dat                       => rx_data,
            t_dav                       => rx_data_req,
            t_ena                       => rx_ready,
            t_pause                     => rx_paused
        );
end architecture rtl;
