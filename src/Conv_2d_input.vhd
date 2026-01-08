library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Utils.all; 

entity Conv_2d_input is
    generic(
        N       : positive := 5;
        M       : positive := 3; 
        Nbit    : positive := 8
    );
    port(
        -- shared with Conv_2d_output
        clk          : in std_logic;
        reset        : in std_logic;
        en_execution : out std_logic;
        filter_out   : out std_logic_vector(M*M - 1 downto 0);
        matrix_out   : out std_logic_vector(N*N - 1 downto 0);
        -- unique   
        x_valid      : in std_logic;
        i_f          : in std_logic;
        x            : in std_logic_vector(Nbit-1 downto 0) -- ;

        --debug 
        -- stato        : out std_logic_vector( clog2((M*M+Nbit-1)/Nbit + (N*N+Nbit-1)/Nbit)-1 downto 0) 
    );
end entity;

architecture C2D of Conv_2d_input is
    -- Custom memory used to save correctly the input data in a matrix form
    component Memory 
        generic(
            Ncell   : positive := 9;
            Nbit_in : positive := 8
        );
        port(
            clk         : in  std_logic;
            resetn      : in  std_logic;
            en           : in  std_logic;
            selector    : in  std_logic_vector(clog2((Ncell + Nbit_in -1)/Nbit_in)-1 downto 0);
            d_in        : in  std_logic_vector(Nbit_in-1 downto 0);
            d_out       : out std_logic_vector(Ncell-1   downto 0)
        );
    end component;

    -- Counter register
    component As_Counter is 
        generic (
            Nbit : positive := 8
        );
        port (
            N_in        : in  std_logic_vector(Nbit - 1 downto 0);
            N_out       : out std_logic_vector(Nbit - 1 downto 0);
            clk         : in  std_logic;
            resetn      : in  std_logic
        );
    end component;

    -- RCA used as subtractor
    component RippleCarryAdder is 
        generic (
            Nbit        : positive := 8
        );
        port (
            a           : in  std_logic_vector(Nbit-1 downto 0);
            b           : in  std_logic_vector(Nbit-1 downto 0);
            cin         : in  std_logic;
            cout        : out std_logic;
            fout        : out std_logic_vector(Nbit-1 downto 0)
        );
    end component;

    constant DIM_FILTER_SELECTOR    : natural := clog2((M*M + Nbit - 1)/Nbit);
    constant DIM_MATRIX_SELECTOR    : natural := clog2((N*N + Nbit - 1)/Nbit);
    constant DIM_BIT_ADDER          : natural := clog2((M*M+Nbit-1)/Nbit + (N*N+Nbit-1)/Nbit);
   
    signal end_filter     :  std_logic; -- 1 when filter loading is complete, 0 otherwise
    signal end_matrix     :  std_logic; -- 1 when matrix loading is complete, 0 altrimenti
    signal count_in       :  std_logic_vector(DIM_BIT_ADDER-1 downto 0); -- counter register's input
    signal count_out      :  std_logic_vector(DIM_BIT_ADDER-1 downto 0); -- counter register's output
    signal in_aus         :  std_logic;
    signal cout_s1_aus    :  std_logic;
    signal fout_s1_aus    :  std_logic_vector(DIM_BIT_ADDER-1 downto 0);
    signal resetn_aus     :  std_logic;
    signal end_filter_aus :  std_logic;
    signal end_matrix_aus :  std_logic;
    signal x_valid_reg    :  std_logic;
    signal i_f_reg        :  std_logic;

    begin 

        resetn_aus <= not reset; 
        end_filter_aus <= not end_filter and i_f and x_valid;

        in_aus <= i_f when end_filter = '0' else not i_f; --discriminates valid input depending on filter state: input is valid when i_f = '1' for filter loading, and when i_f = '0' for matrix loading
        
        count_in(DIM_BIT_ADDER -1 downto 1) <= (others => '0'); 
        count_in(0) <= x_valid and not end_matrix and in_aus; -- used to count the number of correct input recived

        ASC: As_Counter
                generic map(
                    --default 3 bit poichè 
                    -- M*M/Nbit = 9/8 = 1
                    -- N*N/Nbit = 25/8 = 3
                    -- log(4) = 2 ma mi servono almeno 2 + 4 stati => +1
                    Nbit   => DIM_BIT_ADDER
                )
                port map(
                    N_in   => count_in,   
                    N_out  => count_out,      
                    clk    => clk,
                    resetn => resetn_aus          
                );
        -- debug
        -- stato <= count_out;
        

        end_filter <= '1' when unsigned(count_out) > (((M*M+Nbit-1)/Nbit)-1) else '0';
        end_matrix <= '1' when unsigned(count_out) >= (((M*M + Nbit-1)/Nbit) + ((N*N + Nbit-1)/Nbit)) else '0';
        end_matrix_aus <= end_filter and (not end_matrix) and (not i_f) and x_valid;
        en_execution <= end_matrix; -- enables the computation module (handshake signal) once data saving is complete
        
        --Subtractor used to correctly set the matrix memory inputs
        SUB_1: RippleCarryAdder
               generic map (
                    Nbit        => DIM_BIT_ADDER
               )        
               port map(
                    a           => count_out, -- status       
                    b           => std_logic_vector(not to_unsigned((M*M + Nbit -1)/Nbit, DIM_BIT_ADDER)), -- subtract from the status the number of states needed to fill the filter 
                    cin         => '1',
                    cout        => cout_s1_aus,
                    fout        => fout_s1_aus -- input to the matrix memory selector
               );
        -- Filer's memory
        F_MEM: Memory
               generic map (
                    Ncell       => M*M,
                    Nbit_in     => Nbit
               )
               port map(
                    clk         => clk,
                    resetn      => resetn_aus,
                    en          => end_filter_aus,
                    selector    => count_out(DIM_FILTER_SELECTOR-1 downto 0), 
                    d_in        => x,
                    d_out       => filter_out
               );
        -- MAtrix's memory
        M_MEM:  Memory
                generic map(
                    Ncell       => N*N,
                    Nbit_in     => Nbit
                )
                port map(
                    clk         => clk,
                    resetn      => resetn_aus,
                    en          => end_matrix_aus,
                    selector    => fout_s1_aus(DIM_MATRIX_SELECTOR-1 downto 0),
                    d_in        => x,
                    d_out       => matrix_out
                );

        

end architecture;