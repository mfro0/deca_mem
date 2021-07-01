library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library m68k;

entity simple_m68k is
    port
    (
        clk                     : in std_ulogic;
        reset_n                 : in std_ulogic;
        
        uart_out_ready          : in std_ulogic;
        uart_out_data           : out std_ulogic_vector(7 downto 0);
        uart_out_start          : out std_ulogic;
        
        uart_in_data_available  : in std_logic;
        uart_in_data            : in std_ulogic_vector(7 downto 0)
    );
end entity simple_m68k;

architecture rtl of simple_m68k is
    signal mem_data_write,
           mem_data_read        : std_logic_vector(31 downto 0);
           
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
    
    signal addr                 : std_logic_vector(31 downto 0);
    signal cpu_data_in          : std_logic_vector(31 downto 0);
    signal cpu_data_out         : std_logic_vector(31 downto 0);
    signal cpu_data_en          : std_logic;
    signal berr_n               : std_logic;
    signal reset_cpu            : std_logic;
    signal halt_in_n            : std_logic;
    signal halt_out_n           : std_logic;
    signal fc                   : std_logic_vector(2 downto 0);
    signal avec_n               : std_logic;
    signal ipl_n                : std_logic_vector(2 downto 0);
    signal ipend_n              : std_logic;
    signal size                 : std_logic_vector(1 downto 0);
    signal as_n                 : std_logic;
    signal rw_n                 : std_logic;
    signal rmc_n                : std_logic;
    signal ds_n                 : std_logic;
    signal ecs_n                : std_logic;
    signal ocs_n                : std_logic;
    signal dben_n               : std_logic;
    signal bus_en               : std_logic;
    signal sterm_n              : std_logic;
    signal status_n             : std_logic;
    signal refill_n             : std_logic;
    signal br_n                 : std_logic;
    signal bg_n                 : std_logic;
    signal bgack_n              : std_logic;
    
    type dsack_type is (DSACK_FINISH_LONG,      -- "00"
                        DSACK_FINISH_WORD,      -- "01"
                        DSACK_FINISH_BYTE,      -- "10"
                        DSACK_WAIT);            -- "11"
    signal dsack_n              : dsack_type;
    
    -- return a std_logic_vector(1 downto 0) for the enumerated type
    function to_std_logic_vector(ds_n : dsack_type) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(dsack_type'pos(ds_n), 2));
    end function to_std_logic_vector;
    
    constant term_ready_addr    : std_logic_vector(31 downto 0) := x"fffffff0";
    constant term_data_out_addr : std_logic_vector(31 downto 0) := x"fffffff4";
    
begin    
    i_m68k_cpu : entity m68k.wf68k30l_top
        port map
        (
            clk                 => clk,
            
            -- address and data
            ADR_OUT             => addr,
            DATA_IN             => cpu_data_in,
            DATA_OUT            => cpu_data_out,
            DATA_EN             => cpu_data_en,

            -- system control
            BERRn               => berr_n,
            RESET_INn           => reset_n,
            RESET_OUT           => reset_cpu,
            HALT_INn            => halt_in_n,
            HALT_OUTn           => halt_out_n,

            -- processor status
            FC_OUT              => fc,

            -- interrupt control
            AVECn               => avec_n,
            IPLn                => ipl_n,
            IPENDn              => ipend_n,

            -- asynchronous bus control
            DSACKn              => to_std_logic_vector(dsack_n),
            SIZE                => size,
            ASn                 => as_n,
            RWn                 => rw_n,
            RMCn                => rmc_n,
            DSn                 => ds_n,
            ECSn                => ecs_n,
            OCSn                => ocs_n,
            DBENn               => dben_n,
            BUS_EN              => bus_en,

            -- synchronous bus control
            STERMn              => sterm_n,

            -- status controls
            STATUSn             => status_n,
            REFILLn             => refill_n,

            -- bus arbitration control
            BRn                 => br_n,
            BGn                 => bg_n,
            BGACKn              => bgack_n
        );
    
    is_memory_addr <= '1' when unsigned(addr) >= m68k_memory_area.m_start and
                               unsigned(addr) <= m68k_memory_area.m_end else
                               '0';

    memory_addr <= addr(7 downto 2) when is_memory_addr;

    mem_we <= not rw_n;
    -- 
    -- very simple direct attached 256 bytes (for now) of memory
    --
    i_memory : entity work.simple_memory
        generic map
        (
            DATA_WIDTH          => 32,
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
            startup_counter <= 0;
            
        elsif rising_edge(clk) then
            dsack_n <= DSACK_WAIT;
            if startup_counter < 10 then
                startup_counter <= startup_counter + 1;
            else
                if is_memory_addr and not as_n then
                    if not rw_n then
                        mem_data_write <= cpu_data_out;
                        dsack_n <= DSACK_FINISH_LONG;
                    else
                        cpu_data_in <= mem_data_read;
                        dsack_n <= DSACK_FINISH_LONG;
                    end if;
                end if;
            end if;
        end if;
    end process p_cpu_run;
end architecture rtl;
