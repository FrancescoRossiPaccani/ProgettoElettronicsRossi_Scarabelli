library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.Utils.all;

entity Conv_2d_output is
    generic (
        N : positive := 5;
        M : positive := 3
    );
    port(
        -- shared with Conv_2d_in
        clk                 : in  std_logic;
        rst                 : in  std_logic;
        matrix              : in  std_logic_vector(N*N - 1 downto 0);
        filter              : in  std_logic_vector(M*M - 1 downto 0);
        en                  : in  std_logic;
        -- unique
        convolution         : out std_logic_vector(((N - M + 1)*(N - M + 1) * clog2(M*M + 1)) - 1 downto 0 ); -- y
        convolution_ready   : out std_logic -- y_valid
        
    );
end entity;

architecture conv_bh of Conv_2d_output is
    -- dimension of output matrix
    constant OUTPUT_DIMENSION       : natural := N - M + 1;
    constant N_OUTPUT_ELEMENTS      : natural := OUTPUT_DIMENSION * OUTPUT_DIMENSION;
    -- number of bits of the counter
    constant N_BITS_COUNTER         : natural := clog2(N_OUTPUT_ELEMENTS);
    -- number of bits required in order to control the multiplexers
    constant N_BITS_CONTROL_MUX     : natural := clog2(N*N);
    -- number of bits required in order to rapresent one output element
    constant N_BIT_OUTPUT_ELEMENT   : natural := clog2(M*M + 1);

    -- signal used in order to control the multiplexers
    type muc_cntl is array (0 to M*M - 1) of std_logic_vector(N_BITS_CONTROL_MUX - 1 downto 0);
    signal mux_control : muc_cntl;

    -- one bit rapresented over N_BIT_OUTPUT_ELEMENT bits
    type a_ext is array (0 to M*M - 1)of std_logic_vector(N_BIT_OUTPUT_ELEMENT - 1 downto 0);
    signal a_extended : a_ext;

    -- wires used to connect one adder output to the input of the next adder
    type aoai is array (0 to M*M-2) of std_logic_vector(N_BIT_OUTPUT_ELEMENT - 1 downto 0);
    signal adder_out_adder_in   : aoai;

    -- wires connected to the dffs' output
    type odff is array (0 to N_OUTPUT_ELEMENTS-1) of std_logic_vector(N_BIT_OUTPUT_ELEMENT - 1 downto 0);
    signal out_dff              : odff;
    
    signal rst_n                : std_logic;
    
    signal input_counter        : std_logic_vector(N_BITS_COUNTER - 1 downto 0);
    signal output_counter       : std_logic_vector(N_BITS_COUNTER - 1 downto 0);

    signal mux_to_and           : std_logic_vector(M*M - 1 downto 0);
    signal and_to_adder         : std_logic_vector(M*M - 1 downto 0);
    signal adder_to_dff         : std_logic_vector(N_BIT_OUTPUT_ELEMENT - 1 downto 0);
    signal en_dff               : std_logic; 

    -- value of counter
    signal counter_val          : natural := 0;
    -- index of matrix used to select the right submatrix in order to perform the convolution
    signal current_index          : natural := 0;

    -- counter register
    component As_Counter is 
        generic (
            Nbit        : positive := 8
        );
        port (
            N_in        : in  std_logic_vector(Nbit - 1 downto 0);
            N_out       : out std_logic_vector(Nbit - 1 downto 0);
            clk         : in  std_logic;
            resetn      : in  std_logic
        );
    end component;

    -- multiplexer used in order to select the right submatrix in order to perform the convolution
    component mux is
        generic(
            N_input       : positive
        );
        port (
            input_data    : in std_logic_vector(N_input - 1 downto 0);
            control       : in std_logic_vector(clog2(N_input) - 1 downto 0);
            output_data   : out std_logic
        );
    end component;

    -- adder used to perform one iteraction of the convolution
    component RippleCarryAdder is
        generic (
            Nbit    : positive := 8
        );
        port (
            a       : in  std_logic_vector(Nbit-1 downto 0);
            b       : in  std_logic_vector(Nbit-1 downto 0);
            cin     : in  std_logic;
            fout    : out std_logic_vector (Nbit-1 downto 0);
            cout    : out std_logic
        );
    end component;

    -- d flip flop used to store the output of the convolution
    component D_Flip_Flop is
        generic (
            Nbit    : natural := 8
        );
        port (
            clk     : in  std_logic;
            resetn  : in  std_logic;
            en      : in  std_logic;
            di      : in  std_logic_vector(Nbit - 1 downto 0);
            do      : out std_logic_vector(Nbit - 1 downto 0)
        );
    end component;
begin
    -- not reset
    rst_n <= not rst;

    counter_val   <= to_integer(unsigned(output_counter)) when en = '1' and rst = '0' else 0;
    current_index <= ((counter_val / M) * N) + counter_val mod M when en = '1' and rst = '0' else 0;

    input_counter(N_BITS_COUNTER - 1 downto 1) <= (others => '0');
    input_counter(0) <= '1' when (en = '1' and counter_val < N_OUTPUT_ELEMENTS - 1) else '0'; -- conto quando il componente è attivo e finchè non termino l'elaborazione

    counter_i: As_Counter
        generic map(
            Nbit     => N_BITS_COUNTER
        )
        port map(
            clk        => clk,
            resetn     => rst_n,
            N_in       => input_counter,  
            N_out      => output_counter
        );
    
    mux_istances: for i in 0 to M*M - 1 generate
        mux_control(i) <= std_logic_vector(to_unsigned(current_index + (N * (i / M)) + (i mod M), N_BITS_CONTROL_MUX)) when rst = '0' and en = '1' else (others => '0');

        mux_i: mux
            generic map(
                N_input => N*N
            )
            port map(
                input_data   => matrix,
                control      => mux_control(i),
                output_data  => mux_to_and(i)
            );
    end generate;

    and_istances: for i in 0 to M*M - 1 generate
        and_to_adder(i) <= mux_to_and(i) and filter(i);
    end generate;
    
    adders_istances: for i in 0 to M*M - 1 generate
        a_extended(i) <= (0 => and_to_adder(i), others => '0'); 

        adder_first: if i = 0 generate
            adder_0: RippleCarryAdder
            generic map(
                Nbit    => N_BIT_OUTPUT_ELEMENT
            )
            port map(
                a       => a_extended(i),
                b       => (others => '0'),
                cin     => '0',
                fout    => adder_out_adder_in(i),
                cout    => open
            );
        end generate;

        adder_middle: if i > 0 and i < M*M - 1 generate
        adder_i: RippleCarryAdder
            generic map(
                Nbit    => N_BIT_OUTPUT_ELEMENT
            )
            port map(
                a       => a_extended(i),
                b       => adder_out_adder_in(i-1),
                cin     => '0',
                fout    => adder_out_adder_in(i),
                cout    => open
            );
        end generate;
    
        adder_last: if i = M*M - 1 generate    
        adder_MM: RippleCarryAdder
            generic map(
                Nbit    => N_BIT_OUTPUT_ELEMENT
            )
            port map(
                a       => a_extended(i),
                b       => adder_out_adder_in(i-1),
                cin     => '0',
                fout    => adder_to_dff,
                cout    => open
            );
            
        end generate;
    end generate;

    dff_istances: for i in 0 to N_OUTPUT_ELEMENTS - 1 generate
        dff_first: if i = N_OUTPUT_ELEMENTS - 1 generate
            dff_i: D_Flip_Flop
                generic map ( 
                    Nbit     => N_BIT_OUTPUT_ELEMENT 
                )
                port map (
                    clk      => clk,
                    resetn   => rst_n,
                    en       => en_dff,
                    di       => adder_to_dff,
                    do       => out_dff(i)
                );
        end generate;

        dff_seconds: if i >= 0 and i < N_OUTPUT_ELEMENTS-1 generate
            dff_i: D_Flip_Flop
                generic map ( 
                    Nbit     => N_BIT_OUTPUT_ELEMENT 
                )
                port map (
                    clk      => clk,
                    resetn   => rst_n,
                    en       => en_dff,
                    di       => out_dff(i+1),
                    do       => out_dff(i)
                );
        end generate;
    end generate;

    dff_to_output: for i in N_OUTPUT_ELEMENTS - 1 downto 0 generate
        convolution(((i + 1) * N_BIT_OUTPUT_ELEMENT) - 1 downto (i * N_BIT_OUTPUT_ELEMENT)) <= out_dff(i);
    end generate;

    conv_process: process(clk, rst)
    begin
        if rst = '1' then
            en_dff <= '1';
            convolution_ready <= '0';
        elsif rising_edge(clk) then
            if counter_val = N_OUTPUT_ELEMENTS - 1 then
                en_dff <= '0';
                convolution_ready <= '1';
            end if;
        end if;
    end process;

end architecture;