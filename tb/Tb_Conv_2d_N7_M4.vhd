library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Utils.all;  -- se serve per clog2
use std.textio.all;
use IEEE.std_logic_textio.all;

entity Tb_Conv_2d_N7_M4 is
end entity;

architecture tb of Tb_Conv_2d_N7_M4 is

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

    -- Parameters
    constant N       : positive := 7;
    constant M       : positive := 4;
    constant Nbit    : positive := 8;
    constant clk_period : time := 100 ns;

    -- Signals
    signal clk_ext      : std_logic := '0';
    signal reset_ext    : std_logic := '0';
    signal x_valid      : std_logic := '0';
    signal i_f          : std_logic := '0';
    signal x            : std_logic_vector(Nbit-1 downto 0) := (others => '0');
    signal testing      : boolean := true;
    signal y_ext        : std_logic_vector(((N - M + 1)*(N - M + 1) * clog2(M*M+1)) - 1 downto 0);
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
        -- TEST PROCESS 1: Use case with correct piloting, example with the assignments data
        --------------------------------------------------------------------------
        -- 1) RESET iniziale, tutto a zero
        reset_ext <= '1';
        x_valid <= '0';
        i_f <= '0';
        x <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2) 
        --  Filter 1/2
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "10101100";
        wait until rising_edge(clk_ext);
        --  Filter 2/2
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "10011011";
        wait until rising_edge(clk_ext);
        -- 3) 
        -- Matrix 1/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "01010011";
        wait until rising_edge(clk_ext);
        -- Matrix 2/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10111110";
        wait until rising_edge(clk_ext);
        -- Matrix 3/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11110100";
        wait until rising_edge(clk_ext);
        -- Matrix 4/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10001000";
        wait until rising_edge(clk_ext);
        -- Matrix 5/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11100111";
        wait until rising_edge(clk_ext);
        -- Matrix 6/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10111110";
        wait until rising_edge(clk_ext);
        -- Matrix 7/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000001";
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);
        --------------------------------------------------------------------------
        -- TEST PROCESS 2: Use case with correct piloting, same as the previous one 
        -- but only that the "discarded" bits are set to one instead of 0 to verify that they do not impact the system
        --------------------------------------------------------------------------
        -- 1) RESET 
        reset_ext <= '1';
        x_valid <= '0';
        i_f <= '0';
        x <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2) 
        --  Filter 1/2
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "10101100";
        wait until rising_edge(clk_ext);
        --  Filter 2/2
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "10011011";
        wait until rising_edge(clk_ext);
        -- 3) 
        -- Matrix 1/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "01010011";
        wait until rising_edge(clk_ext);
        -- Matrix 2/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10111110";
        wait until rising_edge(clk_ext);
        -- Matrix 3/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11110100";
        wait until rising_edge(clk_ext);
        -- Matrix 4/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10001000";
        wait until rising_edge(clk_ext);
        -- Matrix 5/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11100111";
        wait until rising_edge(clk_ext);
        -- Matrix 6/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10111110";
        wait until rising_edge(clk_ext);
        -- Matrix 7/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);

        --------------------------------------------------------------------------
        -- TEST PROCESS 3: every input data set = '1'
        --------------------------------------------------------------------------
        -- 1) RESET iniziale, tutto a zero
        reset_ext <= '1';
        x_valid <= '0';
        i_f <= '0';
        x <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2) Inserimento Filter
        --  Filter 1/2
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        --  Filter 2/2
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- 3) Inserimento Matrix
        -- Matrix 1/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- Matrix 2/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- Matrix 3/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- Matrix 4/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- Matrix 5/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- Matrix 6/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- Matrix 7/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);

        --------------------------------------------------------------------------
        -- TEST PROCESS 4: every input data set = '0'
        --------------------------------------------------------------------------
        -- 1) RESET 
        reset_ext <= '1';
        x_valid <= '0';
        i_f <= '0';
        x <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2) 
        --  Filter 1/2
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        --  Filter 2/2
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- 3) 
        -- Matrix 1/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- Matrix 2/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- Matrix 3/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- Matrix 4/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- Matrix 5/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- Matrix 6/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- Matrix 7/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);

        --------------------------------------------------------------------------
        -- TEST PROCESS 5: Similar to TEST PROCESS 1 but with some not valid input
        --------------------------------------------------------------------------
        -- 1) RESET iniziale, tutto a zero
        reset_ext <= '1';
        x_valid <= '0';
        i_f <= '0';
        x <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2)
        --  Filter 1/2
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "10101100";
        wait until rising_edge(clk_ext);
        --  Not valid input -> x_valid e i_f wrong
        x_valid     <= '0';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        --  Not valid input -> i_f wrong
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        --  Not valid input -> x_valid must be = '1'
        x_valid     <= '0';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        --  Filter 2/2
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "10011011";
        wait until rising_edge(clk_ext);
        -- 3) 
        -- Not valid input -> i_f wrong
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- Matrix 1/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "01010011";
        wait until rising_edge(clk_ext);
        -- Not valid input -> x_valid e i_f wrong
        x_valid     <= '0';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- Not valid input -> i_f wrong
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- Not valid input -> x_valid wrong
        x_valid     <= '0';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- Matrix 2/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10111110";
        wait until rising_edge(clk_ext);
        -- Matrix 3/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11110100";
        wait until rising_edge(clk_ext);
        -- Matrix 4/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10001000";
        wait until rising_edge(clk_ext);
        -- Matrix 5/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11100111";
        wait until rising_edge(clk_ext);
        -- Matrix 6/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10111110";
        wait until rising_edge(clk_ext);
        -- Matrix 7/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000001";
       
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);

        --------------------------------------------------------------------------
        -- TEST PROCESS 6: Like TEST PROCESS 6 but tryng to change the matrix and the filter during the elaboration phase 
        --------------------------------------------------------------------------
        -- 1) RESET
        reset_ext <= '1';
        x_valid <= '0';
        i_f <= '0';
        x <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2) 
        --  Filter 1/2
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "10101100";
        wait until rising_edge(clk_ext);
        --  Not valid input -> x_valid e i_f wrong
        x_valid     <= '0';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        --  Not valid input -> i_f wrong
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        --  Not valid input -> x_valid corretto
        x_valid     <= '0';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        --  Filter 2/2
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "10011011";
        wait until rising_edge(clk_ext);
        -- 3) Inserimento Matrix
        -- Not valid input -> i_f wrong
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- Matrix 1/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "01010011";
        wait until rising_edge(clk_ext);
        -- Not valid input -> x_valid e i_f wrong
        x_valid     <= '0';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- Not valid input -> i_f wrong
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- Not valid input -> x_valid wrong
        x_valid     <= '0';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- Matrix 2/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10111110";
        wait until rising_edge(clk_ext);
        -- Matrix 3/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11110100";
        wait until rising_edge(clk_ext);
        -- Matrix 4/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10001000";
        wait until rising_edge(clk_ext);
        -- Matrix 5/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11100111";
        wait until rising_edge(clk_ext);
        -- Matrix 6/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10111110";
        wait until rising_edge(clk_ext);
        -- Matrix 7/7
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000001";
        wait until rising_edge(clk_ext);
        -- no change to the data during the processing
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- no change to the data during the processing
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- no change to the data during the processing
        x_valid     <= '0';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- no change to the data during the processing
        x_valid     <= '0';
        i_f         <= '0';
        x           <= "00000000";
      
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);

        -- FINE TEST
        testing <= false;
        wait until rising_edge(clk_ext);
    end process;

end architecture;
