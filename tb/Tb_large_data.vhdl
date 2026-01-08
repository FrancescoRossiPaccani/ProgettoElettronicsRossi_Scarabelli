library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Utils.all;
use std.textio.all;
use IEEE.std_logic_textio.all;

entity Tb_large_data is
end entity;

architecture tb of Tb_large_data is

    component Conv_2d is
    generic(
            N       : positive := 3;
            M       : positive := 5; 
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
            y            : out std_logic_vector(((N - M + 1)*(N - M + 1) * clog2(M*M + 1)) - 1 downto 0);
            y_valid      : out std_logic
        );
    end component;

    -- Parametri
    constant N          : positive := 43;
    constant M          : positive := 32;
    constant Nbit       : positive := 8;
    constant clk_period : time := 100 ns;

    -- Signals
    signal clk_ext      : std_logic := '0';
    signal reset_ext    : std_logic := '0';
    signal x_valid      : std_logic := '0';
    signal i_f          : std_logic := '0';
    signal x            : std_logic_vector(Nbit-1 downto 0) := (others => '0');
    signal testing      : boolean := true;

    signal y_ext        : std_logic_vector(((N - M + 1)*(N - M + 1) * clog2(M*M + 1)) - 1 downto 0);
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
    variable riga : line;
    begin
        --------------------------------------------------------------------------
        -- TEST PROCESS: Use case with correct piloting, all input data = 1
        --------------------------------------------------------------------------
        -- 1) RESET 
        reset_ext   <= '1';
        x_valid     <= '0';
        i_f         <= '0';
        x           <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        reset_ext   <= '0';
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait for 2048*100 ns;
        wait until rising_edge(clk_ext);
        reset_ext   <= '0';
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        wait for 2048*100 ns;
        -- END of this test, witing until y_valid rise to 1 and print in the termnal the output.
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);
    --------------------------------------------------------------------------
    -- TEST PROCESS: Use case with correct piloting
    --------------------------------------------------------------------------
        -- 1) RESET 
        reset_ext   <= '1';
        x_valid     <= '0';
        i_f         <= '0';
        x           <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        reset_ext   <= '0';
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait for 2048*100 ns;
        wait until rising_edge(clk_ext);
        reset_ext   <= '0';
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10101010";
        wait for 2048*100 ns;
        -- END of this test, witing until y_valid rise to 1 and print in the termnal the output.
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);

        wait for 5096*100 ns;
        testing <= false;
        wait for clk_period;
    end process;

end architecture;
