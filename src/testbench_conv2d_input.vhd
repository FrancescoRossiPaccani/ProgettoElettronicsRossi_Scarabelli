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

begin

    --------------------------------------------------------------------------
    -- CLOCK GENERATION
    --------------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk_ext <= '0';
            wait for clk_period/2;
            clk_ext <= '1';
            wait for clk_period/2;
        end loop;
    end process;

    --------------------------------------------------------------------------
    -- UNIT UNDER TEST
    --------------------------------------------------------------------------
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
            x            => x
        );

    --------------------------------------------------------------------------
    -- TEST PROCESS
    --------------------------------------------------------------------------
    stim_proc: process
    begin
        -- 1) RESET iniziale, tutto a zero
        reset_ext <= '1';
        x_valid <= '0';
        i_f <= '0';
        x <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait for clk_period*2;

        -- 2) i_f va a 1 e x va a 11011001
        i_f <= '1';
        x <= "01010101";
        wait for clk_period;

        -- 3) x_valid va a 1
        x_valid <= '1';
        wait for clk_period;

        -- 4) x cambia a 00000001
        x <= "00000001";
        wait for clk_period;

        -- 5) x_valid torna a 0
        x_valid <= '0';
        wait for clk_period;

        -- 6)
        i_f <= '0';
        x <= "11001100";
        x_valid <= '1';
        wait for clk_period;
        --7)
        x <= "00011100";
        wait for clk_period;

        --8)
        x <= "11000111";
        wait for clk_period;
        
        --9)
        x <= "00000001";
        wait for clk_period;

        -- Fine simulazione
        wait for clk_period*5;
        assert false report "FINE SIMULAZIONE" severity failure;
    end process;

end architecture;
