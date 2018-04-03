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
    signal tg68_wr_n            : std_logic;
    signal tg68_fc              : std_logic_vector(2 downto 0);
    signal tg68_busstate        : std_logic_vector(1 downto 0);
    signal tg68_reset_n         : std_logic;
    
    signal clk_ena              : std_logic;
    signal cpu_data_in          : std_logic_vector(15 downto 0);
    signal tg68_berr            : std_logic;
    signal tg68_clr_berr        : std_logic;
    
    signal mem_data_write,
           mem_data_read        : std_logic_vector(15 downto 0);
           
    constant MEMORY_ADDR_WIDTH  : integer := 6;
    
    type memory_area_type is record
        m_start,
        m_end                   : unsigned(31 downto 0);
    end record memory_area_type;
    
    constant m68k_memory_area   : memory_area_type :=
    (
        m_start                 => (others => '0'),
        m_end                   => to_unsigned(MEMORY_ADDR_WIDTH - 1, 32)
    );
    
    signal memory_addr          : std_logic_vector(MEMORY_ADDR_WIDTH - 1 downto 0);
    signal is_memory_addr       : std_logic;
    
    signal mem_we               : std_logic;
    
    signal startup_counter      : integer := 0;
    
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
            nWR                 => tg68_wr_n,
            busstate            => tg68_busstate,
            nResetOut           => tg68_reset_n,
            FC                  => tg68_fc
        );
    
    is_memory_addr <= '1' when unsigned(tg68_addr) >= m68k_memory_area.m_start and unsigned(tg68_addr) <= m68k_memory_area.m_end else
                      '0';
    memory_addr <= tg68_addr(MEMORY_ADDR_WIDTH downto 1) when is_memory_addr;

    mem_we <= not tg68_wr_n;
    -- 
    -- very simple direct attached 128 bytes (for now) of memory
    --
    i_memory : entity work.simple_memory
        generic map
        (
            DATA_WIDTH          => 16,
            ADDR_WIDTH          => MEMORY_ADDR_WIDTH
        )
        port map
        (
            clk                 => clk,
            reset_n             => reset_n,
            
            addr_in             => memory_addr,
            data                => mem_data_write,
            we                  => mem_we,
            q                   => mem_data_read
        );

    p_cpu_run : process(all)
    begin
        if not reset_n then
            clk_ena <= '0';
            tg68_ipl <= (others => '1');
            tg68_berr <= '0';
            tg68_clr_berr <= '0';
            
            startup_counter <= 0;
            
        elsif rising_edge(clk) then
            if startup_counter < 10 then
                startup_counter <= startup_counter + 1;
            else
                clk_ena <= '1';
                if is_memory_addr then
                    if not tg68_wr_n then
                        null;
                    else
                        cpu_data_in <= mem_data_read;
                    end if;
                end if;
            end if;
        end if;
    end process p_cpu_run;
end architecture rtl;
