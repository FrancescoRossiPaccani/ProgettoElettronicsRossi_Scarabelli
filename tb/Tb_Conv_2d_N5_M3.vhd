library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Utils.all;  -- se serve per clog2

entity Tb_Conv_2d_N5_M3 is
end entity;

architecture tb of Tb_Conv_2d_N5_M3 is

    component Conv_2d is
    generic(
            N       : positive := 5;
            M       : positive := 3; 
            Nbit    : positive := 8
        );
        port(

            clk          : in std_logic;
            reset        : in std_logic;         
            -- input
            x_valid      : in std_logic;
            i_f          : in std_logic;
            x            : in std_logic_vector(Nbit-1 downto 0);
            -- output
            y            : out std_logic_vector(((N - M + 1)*(N - M + 1) * clog2(M*M +1 )) - 1 downto 0);
            y_valid      : out std_logic
        );
    end component;

    -- Parametri
    constant N          : positive := 5;
    constant M          : positive := 3;
    constant Nbit       : positive := 8;
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

    signal y_ext        : std_logic_vector(((N - M + 1)*(N - M + 1) * clog2(M*M)) - 1 downto 0);
    signal y_valid_ext  : std_logic;
begin
     clk_ext <= not clk_ext after clk_period/2 when testing else '0';

    UUT: Conv_2d
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
        -- TEST PROCESS: Caso d'uso con corretto pilotaggio, esempio consegna
        --------------------------------------------------------------------------
        -- 1) RESET iniziale, tutto a zero
        reset_ext   <= '1';
        x_valid     <= '0';
        i_f         <= '0';
        x           <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2) Inzio a registrare il filtro, primi 8 elementi
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "01010101";
        wait until rising_edge(clk_ext);
        -- 3) Continuo a registrare il filtro, ultimo elemento
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "00000001";
        wait until rising_edge(clk_ext);
        -- 4) Inizio a registrare la matrice 8 elementi alla volta
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11001100";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00011100";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11000111";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000001";
        wait until rising_edge(clk_ext);

        -- fine aspetto un po' e vedo il risutato quando y_vlaid = 1
        wait for 20*100 ns;
        wait until rising_edge(clk_ext);

        --------------------------------------------------------------------------
        -- TEST PROCESS: Caso d'uso con corretto pilotaggio, solamente che i bit "scartati" sono ad uno anzich è 0 
        -- per verificare che non impattano sul sistema
        --------------------------------------------------------------------------
        -- 1) RESET iniziale, tutto a zero
        reset_ext   <= '1';
        x_valid     <= '0';
        i_f         <= '0';
        x           <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2) Inzio a registrare il filtro, primi 8 elementi
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "01010101";
        wait until rising_edge(clk_ext);
        -- 3) Continuo a registrare il filtro, ultimo elemento
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";   -- <--- Cambia qua
        wait until rising_edge(clk_ext);
        -- 4) Inizio a registrare la matrice 8 elementi alla volta
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11001100";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00011100";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11000111";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";   -- <--- Cambia qua
        wait until rising_edge(clk_ext);

        -- fine aspetto un po' e vedo il risutato quando y_vlaid = 1
        wait for 20*100 ns;
        wait until rising_edge(clk_ext);

        --------------------------------------------------------------------------
        -- TEST PROCESS: Caso d'uso con corretto pilotaggio, caso limite solo 1, il risutato deve essere pari alla dimensione del filtro in questo caso un array di 9
        --------------------------------------------------------------------------
         -- 1) RESET iniziale, tutto a zero
        reset_ext   <= '1';
        x_valid     <= '0';
        i_f         <= '0';
        x           <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2) Inzio a registrare il filtro, primi 8 elementi
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- 3) Continuo a registrare il filtro, ultimo elemento
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";   
        wait until rising_edge(clk_ext);
        -- 4) Inizio a registrare la matrice 8 elementi alla volta
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";   
        wait until rising_edge(clk_ext);

        -- fine aspetto un po' e vedo il risutato quando y_vlaid = 1
        wait for 20*100 ns;
        wait until rising_edge(clk_ext);

        --------------------------------------------------------------------------
        -- TEST PROCESS: Caso d'uso con pilotaggio scorretto, input solamente 1 usato per verificare il comportamento quando gli ingressi variano e creano delle corse
        --------------------------------------------------------------------------
         -- 1) RESET iniziale, tutto a zero
        reset_ext   <= '1';
        x_valid     <= '0';
        i_f         <= '0';
        x           <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2) Inzio a registrare il filtro, primi 8 elementi
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- 3) Qua non registro nulla
        x_valid     <= '0';
        i_f         <= '0';
        x           <= "11111111";   
        wait until rising_edge(clk_ext);
        -- 4) Neanche qua registro nulla
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- 5) Neanche qua registro nulla
        x_valid     <= '0';
        i_f         <= '1';
        x           <= "11111111";   
        wait until rising_edge(clk_ext);
        -- 6) registro correttemente il filtro
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- 7) Inizio a registrare la matrice 8 elementi alla volta
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10101010";
        wait until rising_edge(clk_ext);
        -- 8) Stessi errori di prima non devo registrare nulla
        x_valid     <= '0';
        i_f         <= '0';
        x           <= "10101010";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";   -- <--- Cambia qua
        wait until rising_edge(clk_ext);
        

        wait for 1024*100 ns;
        testing <= false;
        wait for clk_period;
    end process;

end architecture;
