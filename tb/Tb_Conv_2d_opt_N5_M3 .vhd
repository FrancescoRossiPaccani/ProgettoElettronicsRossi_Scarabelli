library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Utils.all;
use std.textio.all;
use IEEE.std_logic_textio.all;

entity Tb_Conv_2d_opt_N5_M3 is
end entity;

architecture tb of Tb_Conv_2d_opt_N5_M3 is

    component Conv_2d_opt is
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
    constant N          : positive := 5;
    constant M          : positive := 3;
    constant Nbit       : positive := 8;
    constant clk_period : time := 100 ns;

    -- Signals
    signal clk_ext      : std_logic := '0';
    signal reset_ext    : std_logic := '0';
    signal x_valid      : std_logic := '0';
    signal i_f          : std_logic := '0';
    signal x            : std_logic_vector(Nbit-1 downto 0) := (others => '0');
    signal testing      : boolean := true;

    signal y_ext        : std_logic_vector(((N - M + 1)*(N - M + 1) * clog2(M*M)) - 1 downto 0);
    signal y_valid_ext  : std_logic;

begin
     clk_ext <= not clk_ext after clk_period/2 when testing else '0';

    UUT: Conv_2d_opt
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
        -- 1) RESET, every data set to 0
        reset_ext   <= '1';
        x_valid     <= '0';
        i_f         <= '0';
        x           <= (others => '0');
        wait until rising_edge(clk_ext);
        -- 2) Starting to save the first 8 elements of the filter
        reset_ext <= '0';
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "01010101";
        wait until rising_edge(clk_ext);
        -- 3) Continue to record the filter, last item        
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "00000001";
        wait until rising_edge(clk_ext);
        -- 4) Starting to save the first 8 element of the matrix
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


        -- END of this test, witing until y_valid rise to 1 and print in the termnal the output.
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);


        --------------------------------------------------------------------------
        -- TEST PROCESS 2: Use case with correct piloting, same as the previous one 
        -- but only that the "discarded" bits are set to one instead of 0 to verify that they do not impact the system
        --------------------------------------------------------------------------
        -- 1) RESET, every data set to 0
        reset_ext   <= '1';
        x_valid     <= '0';
        i_f         <= '0';
        x           <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2) Starting to save the first 8 elements of the filter
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "01010101";
        wait until rising_edge(clk_ext);
        -- 3) Continue to record the filter, last item   
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";   -- <--- 
        wait until rising_edge(clk_ext);
        -- 4) Starting to save the first 8 element of the matrix
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
        x           <= "11111111";   -- <--- 

        -- END of this test, witing until y_valid rise to 1 and print in the termnal the output.
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);

        --------------------------------------------------------------------------
        -- TEST PROCESS 3: Use case with correct driving, limit case all input data = 1, 
        -- the result must be equal to the filter size in this case an array of 9
        --------------------------------------------------------------------------
         -- 1) RESET 
        reset_ext   <= '1';
        x_valid     <= '0';
        i_f         <= '0';
        x           <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2)
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- 3) 
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";   
        wait until rising_edge(clk_ext);
        -- 4) 
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        --5)
        wait until rising_edge(clk_ext);
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        --6)
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        --7)
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "11111111";  

        -- END of this test, witing until y_valid rise to 1 and print in the termnal the output.
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);

        --------------------------------------------------------------------------
        -- TEST PROCESS 4: Use case with correct driving, limit case all input data = 0, the result will be an array of all 0s
        --------------------------------------------------------------------------
         -- 1) RESET 
        reset_ext   <= '1';
        x_valid     <= '0';
        i_f         <= '0';
        x           <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2) 
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- 3) 
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "00000000";   
        wait until rising_edge(clk_ext);
        -- 4) 
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";   
        wait until rising_edge(clk_ext);

        -- END of this test, witing until y_valid rise to 1 and print in the termnal the output.
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);
        --------------------------------------------------------------------------
        -- TEST PROCESS 5: Use case with incorrect driving, input data =  1 input 
        -- used to test the behavior when the inputs vary and create races
        --------------------------------------------------------------------------
         -- 1) RESET 
        reset_ext   <= '1';
        x_valid     <= '0';
        i_f         <= '0';
        x           <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2) 
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- 3) Inputs are not in a valid state so they are ignored 
        x_valid     <= '0';
        i_f         <= '0';
        x           <= "00000000";   
        wait until rising_edge(clk_ext);
        -- 4) Still inputs in a not valid state  
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- 5) Still inputs in a not valid state
        x_valid     <= '0';
        i_f         <= '1';
        x           <= "00000000";   
        wait until rising_edge(clk_ext);
        -- 6) Still inputs in a not valid state 
        x_valid     <= '0';
        i_f         <= '0';
        x           <= "00000000";   
        wait until rising_edge(clk_ext);
        -- 7) Inputs in a valid state
         x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- 8) Inputs not in a valid state
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- 9) Inputs in a valid state, starting to save the matrix
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10101010";
        wait until rising_edge(clk_ext);
        -- 10) Same input as before, not in a valid state
        x_valid     <= '0';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);

        x_valid     <= '0';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);

        x_valid     <= '0';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);

        -- 11) Input in a valid state
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10101010";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10101010";   
        wait until rising_edge(clk_ext);
        
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10101010";   
        wait until rising_edge(clk_ext);

        -- 12) Expected output in hex 454 - 545 - 454
        --     If at least one unexpected input had been saved the output would be different
       
        -- END of this test, witing until y_valid rise to 1 and print in the termnal the output.
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);

        --------------------------------------------------------------------------
        -- TEST PROCESS 6: Same example as before but I try to change the filter during execution
        --------------------------------------------------------------------------
         -- 1) RESET
        reset_ext   <= '0';
        x_valid     <= '0';
        i_f         <= '0';
        x           <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2) 
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- 3) Inputs are not in a valid state so they are ignored 
        x_valid     <= '0';
        i_f         <= '0';
        x           <= "00000000";   
        wait until rising_edge(clk_ext);
        -- 4) Still inputs in a not valid state
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);
        -- 5) Still inputs in a not valid state
        x_valid     <= '0';
        i_f         <= '1';
        x           <= "00000000";   
        wait until rising_edge(clk_ext);
        -- 6) Still inputs in a not valid state
        x_valid     <= '0';
        i_f         <= '0';
        x           <= "00000000";   
        wait until rising_edge(clk_ext);
        -- 7) Inputs in a valid state
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- 8) Inputs not in a valid state
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- 9) Inizio a registrare la matrice 8 elementi alla volta
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10101010";
        wait until rising_edge(clk_ext);
        -- 10) Inputs in a valid state, starting to save the matrix
        x_valid     <= '0';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);

        x_valid     <= '0';
        i_f         <= '0';
        x           <= "00000000";
        wait until rising_edge(clk_ext);

        x_valid     <= '0';
        i_f         <= '1';
        x           <= "00000000";
        wait until rising_edge(clk_ext);

        -- 11) Qua corretto funzionamento salvo questi valori
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10101010";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10101010";   
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10101010";   
        wait until rising_edge(clk_ext);
        -- 12) Tryng to change the filter
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "00000000";   -- <---  
        wait until rising_edge(clk_ext);
         -- 10) Expected output in hex 454 - 545 - 454
         --     If at least one unexpected input had been saved the output would be different
        
         -- END of this test, witing until y_valid rise to 1 and print in the termnal the output.
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);
        --------------------------------------------------------------------------
        -- TEST PROCESS 7: Sequential input with correct piloting, 
        --------------------------------------------------------------------------
        -- 1) RESET, every data set to 0
        reset_ext   <= '1';
        x_valid     <= '0';
        i_f         <= '0';
        x           <= (others => '0');
        wait for 200 ns;
        reset_ext <= '0';
        wait until rising_edge(clk_ext);
        -- 2) Starting to save the first 8 elements of the filter
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "01010101";
        wait until rising_edge(clk_ext);
        -- 3) Continue to record the filter, last item   
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";   -- <--- 
        wait until rising_edge(clk_ext);
        -- 4) Starting to save the first 8 element of the matrix
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
        x           <= "11111111";   -- <--- 

        -- END of this pseudotest, witing until y_valid rise to 1 and print in the termnal the output.
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until falling_edge(y_valid_ext);
        wait until rising_edge(clk_ext);
        --- Second data stream
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";
        wait until rising_edge(clk_ext);
        -- 3) Continue to record the filter, last item   
        x_valid     <= '1';
        i_f         <= '1';
        x           <= "11111111";   -- <--- 
        wait until rising_edge(clk_ext);
        -- 4) Starting to save the first 8 element of the matrix
        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10101010";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10101010";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10101010";
        wait until rising_edge(clk_ext);

        x_valid     <= '1';
        i_f         <= '0';
        x           <= "10101010";   -- <--- 

        -- END of this test, witing until y_valid rise to 1 and print in the termnal the output.
        wait until rising_edge(y_valid_ext);
        write(riga, y_ext);
        writeline(output, riga);
        wait until rising_edge(clk_ext);

        wait for 20*100 ns;
        testing <= false;
        wait for clk_period;
    end process;

end architecture;
