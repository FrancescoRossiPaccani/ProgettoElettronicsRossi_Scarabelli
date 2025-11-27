library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Utils.all; 

entity tb_memory is
end entity;

architecture tb of tb_memory is

    -- Parametri della memoria
    constant Ncell   : positive := 9;
    constant Nbit_in : positive := 8;
    constant clk_period : time := 100 ns;

    component Memory
        generic(
            Ncell   : positive;
            Nbit_in : positive
        );
        port(
            clk      : in  std_logic;
            resetn   : in  std_logic;
            en       : in  std_logic;
            selector : in  std_logic_vector(clog2((Ncell + Nbit_in -1)/Nbit_in)-1 downto 0);
            d_in     : in  std_logic_vector(Nbit_in-1 downto 0);
            d_out    : out std_logic_vector(Ncell-1 downto 0)
        );
    end component;

    -- Signals
    signal clk_ext      : std_logic := '0';
    signal resetn_ext   : std_logic := '0';
    signal en_aus       : std_logic := '0';
    signal selector_ext : std_logic_vector(clog2((Ncell + Nbit_in -1)/Nbit_in)-1 downto 0) := (others => '0');
    signal d_in_ext     : std_logic_vector(Nbit_in-1 downto 0) := (others => '0');
    signal d_out_ext    : std_logic_vector(Ncell-1 downto 0);

    signal testing : boolean := true;

begin

    --------------------------------------------------------------------------
    -- CLOCK
    --------------------------------------------------------------------------
    clk_ext <= not clk_ext after clk_period/2 when testing else '0';

    --------------------------------------------------------------------------
    -- UUT: Memory
    --------------------------------------------------------------------------
    i_MEM: Memory
        generic map(
            Ncell   => Ncell,
            Nbit_in => Nbit_in
        )
        port map(
            clk      => clk_ext,
            resetn   => resetn_ext,
            en       => en_aus,
            selector => selector_ext,
            d_in     => d_in_ext,
            d_out    => d_out_ext
        );

    --------------------------------------------------------------------------
    -- SIMULATION PROCESS
    --------------------------------------------------------------------------
    p_SIM: process
    begin
        testing <= true;

        -- RESET
        en_aus <= '0';
        resetn_ext <= '0';
        d_in_ext <= (others => '0');
        selector_ext <= (others => '0');
        wait for 200 ns;
        resetn_ext <= '1';
        wait until rising_edge(clk_ext);

        ----------------------------------------------------------------------
        -- TEST 1: Scrivo primo blocco (selector = 0)
        ----------------------------------------------------------------------
        report "TEST 1: selector = 0 -> abilita primi Nbit_in bit";
        en_aus <= '1';
        selector_ext <= (others => '0');  -- sel_int = 0
        d_in_ext <= "10101010";           -- esempio pattern
        wait until rising_edge(clk_ext);

        ----------------------------------------------------------------------
        -- TEST 2: Scrivo secondo blocco (selector = 1) - caso limite
        ----------------------------------------------------------------------
        report "TEST 2: selector = 1 -> ultimo blocco (parziale)";
        selector_ext <= "1";             -- sel_int = 1
        d_in_ext <= "00000001";           -- scrivi solo ultimo bit
        wait until rising_edge(clk_ext);

        ----------------------------------------------------------------------
        -- TEST 3: Cambio dati nello stesso blocco
        ----------------------------------------------------------------------
        report "TEST 3: cambio dati selector=1";
        selector_ext <= "1";
        d_in_ext <= "01110000";
        wait until rising_edge(clk_ext);

        ----------------------------------------------------------------------
        -- TEST 4: Ritorno al primo blocco
        ----------------------------------------------------------------------
        report "TEST 4: ritorno a selector=0";
        selector_ext <= "0";
        d_in_ext <= "00001111";
        wait until rising_edge(clk_ext);

        ----------------------------------------------------------------------
        -- TEST 5: Disabilita enable
        ----------------------------------------------------------------------
        report "TEST 5: en='0' blocco inattivo";
        en_aus <= '0';
        selector_ext <= "0";
        d_in_ext <= "11111111";
        wait until rising_edge(clk_ext);

        ----------------------------------------------------------------------
        -- FINE SIMULAZIONE
        ----------------------------------------------------------------------
        wait for 500 ns;
        testing <= false;
        wait;
    end process;

end architecture;
