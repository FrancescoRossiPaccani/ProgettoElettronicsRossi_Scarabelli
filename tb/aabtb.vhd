library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Utils.all;  -- se serve per clog2

entity AABtb_Conv_2d is
end entity;

architecture tb of AABtb_Conv_2d is

    -- Parametri
    constant N       : positive := 7;
    constant M       : positive := 4;
    constant Nbit    : positive := 8;
    constant clk_period : time := 100 ns;

    -- Signals
    signal clk_ext      : std_logic := '0';
    signal reset_ext    : std_logic := '0';
    -- signal en_execution : std_logic;
    -- signal filter_out   : std_logic_vector(M*M-1 downto 0);
    -- signal matrix_out   : std_logic_vector(N*N-1 downto 0);
    signal x_valid      : std_logic := '0';
    signal i_f          : std_logic := '0';
    signal x            : std_logic_vector(Nbit-1 downto 0) := (others => '0');
    signal testing      : boolean := true;
    -- signal stato_aus    : std_logic_vector( clog2((M*M+Nbit-1)/Nbit + (N*N+Nbit-1)/Nbit)-1 downto 0) ;

    signal y_ext        : std_logic_vector(((N - M + 1)*(N - M + 1) * clog2(M*M+1)) - 1 downto 0);
    signal y_valid_ext  : std_logic;
begin
     clk_ext <= not clk_ext after clk_period/2 when testing else '0';
    -- Conv_2d
    UUT: entity work.wrapper_conv_2d 
        generic map(
            N    => N,
            M    => M,
            Nbit => Nbit
        )
        port map(
            clk          => clk_ext,
            reset        => reset_ext,
            
            x_valid      => x_valid,
            i_f          => i_f,
            x            => x,
           
            y            => y_ext,
            y_valid      => y_valid_ext
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
        x <= "11111111";
        i_f <= '1';
        x_valid <= '1';
        wait until rising_edge(clk_ext);
        x <= "11111111";
        i_f <= '1';
        x_valid <= '1';
        --wait until rising_edge(clk_ext);
        --x <= "11111111";
        --i_f <= '1';
        x_valid <= '1';
        wait until rising_edge(clk_ext);
        x <= "11111111";
        i_f <= '0';
        x_valid <= '1';
        wait until rising_edge(clk_ext);
         x <= "11111111";
        i_f <= '0';
        x_valid <= '1';
        wait until rising_edge(clk_ext);
         x <= "11111111";
        i_f <= '0';
        x_valid <= '1';
        wait until rising_edge(clk_ext);
         x <= "11111111";
        i_f <= '0';
        x_valid <= '1';
        wait until rising_edge(clk_ext);
         x <= "11111111";
        i_f <= '0';
        x_valid <= '1';
        wait until rising_edge(clk_ext);
         x <= "11111111";
        i_f <= '0';
        x_valid <= '1';
        wait until rising_edge(clk_ext);
         x <= "11111111";
        i_f <= '0';
        x_valid <= '1';
        wait until rising_edge(clk_ext);
         x <= "11111111";
        i_f <= '0';
        x_valid <= '1';
        wait until rising_edge(clk_ext);

        --10) Fine 1
        wait for 4096*100 ns;
        wait until rising_edge(clk_ext);


        -- assert false report "FINE SIMULAZIONE" severity failure;
        wait for 4096*100 ns;
        testing <= false;
        wait for clk_period;
    end process;

end architecture;
