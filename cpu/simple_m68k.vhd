library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simple_m68k is
    port
    (
        clk                     : in std_logic;
        reset_n                 : in std_logic
    );
end entity simple_m68k;

architecture rtl of simple_m68k is
    signal tg68_data_out        : std_logic_vector(15 downto 0);
    signal tg68_addr            : std_logic_vector(31 downto 0);
    signal tg68_ipl             : std_logic_vector(2 downto 0);
    signal tg68_dtack           : std_logic;
    signal tg68_uds,
           tg68_lds             : std_logic;
    signal tg68_rw              : std_logic;
    signal tg68_fc              : std_logic_vector(2 downto 0);
    signal tg68_busstate        : std_logic_vector(1 downto 0);
    signal tg68_reset_n         : std_logic;
    
    signal clk_ena              : std_logic;
    signal cpu_data_in          : std_logic_vector(15 downto 0);
    signal tg68_berr            : std_logic;
    signal tg68_clr_berr        : std_logic;
    
    signal mem_data_write,
           mem_data_read        : std_logic_vector(15 downto 0);
    
begin
    i_m68k_cpu : entity work.tg68kdotC_kernel
        generic map
        (
            2, 2, 2, 2, 2, 2, 2
        )
        port map
        (
            clk                 => clk,
            nReset              => reset_n,
            clkena_in           => clk_ena,
            data_in             => cpu_data_in,
            ipl                 => tg68_ipl,
            ipl_autovector      => '0',
            berr                => tg68_berr,
            clr_berr            => tg68_clr_berr,
            cpu                 => "00",
            addr_out            => tg68_addr,
            data_write          => tg68_data_out,
            nUDS                => tg68_uds,
            nLDS                => tg68_lds,
            nWR                 => tg68_rw,
            busstate            => tg68_busstate,
            nResetOut           => tg68_reset_n,
            FC                  => tg68_fc
        );
    
    -- 
    -- very simple direct attached 128 bytes (for now) of memory
    --
    i_memory : entity work.simple_memory
        generic map
        (
            DATA_WIDTH          => 16,
            ADDR_WIDTH          => 6
        )
        port map
        (
            clk                 => clk,
            reset_n             => reset_n,
            
            addr_in             => tg68_addr(6 - 1 downto 0),
            data                => mem_data_write,
            we                  => tg68_rw,
            q                   => mem_data_read
        );
end architecture rtl;
