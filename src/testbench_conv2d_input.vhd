library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Utils.all;  -- se serve per clog2

entity tb_Conv_2d_input is
end entity;

architecture tb of tb_Conv_2d_input is

    -- Parametri
    constant N       : positive := 5;
    constant M       : positive := 3;
    constant Nbit    : positive := 8;
    constant clk_period : time := 100 ns;

    -- Signals
    signal clk_ext      : std_logic := '0';
    signal reset_ext    : std_logic := '0';
    signal en_execution : std_logic;
    signal filter_out   : std_logic_vector(M*M-1 downto 0);
    signal matrix_out   : std_logic_vector(N*N-1 downto 0);
    signal x_valid      : std_logic := '0';
    signal i_f          : std_logic := '0';
    signal x            : std_logic_vector(Nbit-1 downto 0) := (others => '0');
    signal testing      : boolean := true;
    signal stato_aus    : std_logic_vector( clog2((M*M+Nbit-1)/Nbit + (N*N+Nbit-1)/Nbit)-1 downto 0) ;
begin
     clk_ext <= not clk_ext after clk_period/2 when testing else '0';

    UUT: entity work.Conv_2d_input
        generic map(
            N    => N,
            M    => M,
            Nbit => Nbit
        )
        port map(
            clk          => clk_ext,
            reset        => reset_ext,
            en_execution => en_execution,
            filter_out   => filter_out,
            matrix_out   => matrix_out,
            x_valid      => x_valid,
            i_f          => i_f,
            x            => x,
            stato => stato_aus
        );

    stim_proc: process
    begin
        --------------------------------------------------------------------------
        -- TEST PROCESS: Caso d'uso con corretto pilotaggio
        --------------------------------------------------------------------------
        -- 1) RESET iniziale, tutto a zero
        reset_ext <= '1';
        x_valid <= '0';
        i_f <= '0';
        x <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);

        -- 2) i_f va a 1 e x va a 11011001
        wait for 10 ns;
        i_f <= '1';
        x <= "01010101";
        wait until rising_edge(clk_ext);

        -- 3) x_valid va a 1
        wait for 10 ns;
        x_valid <= '1';
        wait until rising_edge(clk_ext);

        -- 4) x cambia a 00000001
        wait for 10 ns;
        x <= "00000001";
        wait until rising_edge(clk_ext);

        -- 5) x_valid torna a 0
        wait for 10 ns;
        x_valid <= '0';
        wait until rising_edge(clk_ext);

        -- 6)
        wait for 10 ns;
        i_f <= '0';
        x <= "11001100";
        x_valid <= '1';
        wait until rising_edge(clk_ext);
        --7)
        wait for 10 ns;
        x <= "00011100";
        wait until rising_edge(clk_ext);

        --8)
        wait for 10 ns;
        x <= "11000111";
        wait until rising_edge(clk_ext);
        
        --9)
        wait for 10 ns;
        x <= "00000001";
        wait until rising_edge(clk_ext);

        --10) Fine 1
        wait for 4096*100 ns;
        wait until rising_edge(clk_ext);

        --------------------------------------------------------------------------
        -- TEST PROCESS: Caso d'uso con corretto pilotaggio
        --------------------------------------------------------------------------

        -- 1) RESET iniziale, tutto a zero
        reset_ext <= '1';
        x_valid <= '0';
        i_f <= '0';
        x <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);

        -- 2) x va a 11011001, x_valid va a 1 ma i/f non cambia
        wait for 10 ns;
        i_f <= '0';
        x_valid <= '1';
        x <= "11111111"; -- qua le memorie devono rimanere a 0
        wait until rising_edge(clk_ext);

        -- 2) Caso contrario 
        wait for 20 ns;
        x_valid <= '0';
        i_f <= '1';
        x <= "11110001"; -- qua le memorie devono rimanere a 0
        wait until rising_edge(clk_ext);

        -- 3) Caso durante un ciclo di clock x_valid e i/f cambianp
        wait for 40 ns;
        x_valid <= '1';
        wait for 15 ns;
        i_f <= '0';
        wait for 30 ns;
        x_valid <= '0';
        i_f <= '1';
        x <= "01010101"; -- qua le memorie devono rimanere a 0
        wait until rising_edge(clk_ext);

        -- 4) Caso concorrente
        x_valid <= '0';
        i_f <= '1';
        x <= "11111111";
        wait until rising_edge(clk_ext);

        -- 4) Caso concorrente 2
        x_valid <= '1';
        i_f <= '0';
        x <= "11111111";
        wait until rising_edge(clk_ext);

        --5) salvo correttamente il filtro
        i_f <= '1';
        x_valid <= '1';
        x <= "01010101";
        wait until rising_edge(clk_ext);

        i_f <= '1';
        x_valid <= '1';
        x <= "00000001";
        wait until rising_edge(clk_ext);

        --6) attendo un po'
        wait until rising_edge(clk_ext);
        wait until rising_edge(clk_ext);
        wait until rising_edge(clk_ext);

        --7) inziio a salvare la matrice
        i_f <= '0';
        x_valid <= '1';
        x <= "11001100";
        wait until rising_edge(clk_ext);
        i_f <= '1';
        x_valid <= '1';
        x <= "11111111";
        wait until rising_edge(clk_ext);
        i_f <= '0';
        x_valid <= '0';
        wait until rising_edge(clk_ext);
        -- 8) finisco di salvare la matrice
        x_valid <= '1';
        x <= "00011100";
        wait until rising_edge(clk_ext);
        
        x <= "11000111";
        wait until rising_edge(clk_ext);

        x <= "00000001";
        wait until rising_edge(clk_ext);

        x_valid <= '0';


        -- assert false report "FINE SIMULAZIONE" severity failure;
        wait for 4096*100 ns;
        testing <= false;
        wait for clk_period;
    end process;

end architecture;
