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
        -- condivise con modulo Conv_2d_in
        clk                 : in  std_logic;
        rst                 : in  std_logic;
        matrix              : in  std_logic_vector(N*N - 1 downto 0);
        filter              : in  std_logic_vector(0 to M*M - 1 );
        en                  : in  std_logic;
        -- uniche
        convolution         : out std_logic_vector(((N - M + 1)*(N - M + 1) * clog2(M*M + 1)) - 1 downto 0 ); -- y
        convolution_ready   : out std_logic -- y_valid
        
    );
end entity;

architecture conv_bh of Conv_2d_output is
    constant OUTPUT_DIMENSION       : natural := N - M + 1;
    constant N_OUTPUT_ELEMENTS      : natural := OUTPUT_DIMENSION*OUTPUT_DIMENSION;
    constant N_BITS_COUNTER         : natural := clog2(N_OUTPUT_ELEMENTS);
    constant N_BITS_CONTROL_MUX     : natural := clog2(N*N);
    constant N_BIT_OUTPUT_ELEMENT   : natural := clog2(M*M + 1);

    type slv is array (natural range <>) of std_logic_vector(N_BIT_OUTPUT_ELEMENT - 1 downto 0);

    signal rst_n                : std_logic;
    signal en_counter           : std_logic;
    signal output_counter       : std_logic_vector(N_BITS_COUNTER - 1 downto 0);
    signal mux_to_and           : std_logic_vector(M*M - 1 downto 0);
    signal and_to_adder         : std_logic_vector(M*M - 1 downto 0);
    signal adder_out_adder_in   : slv(M*M - 2 downto 0);
    signal adder_to_dff         : std_logic_vector(N_BIT_OUTPUT_ELEMENT - 1 downto 0);
    signal out_dff              : slv(N_OUTPUT_ELEMENTS - 1 downto 0);
    signal en_dff               : std_logic; 

    signal counter_val          : integer := 0;
    signal current_row          : integer := 0;
    signal current_col          : integer := 0;

    -- ** da mettere AS_Counter
    component Counter is
        generic (
            N : natural := 8
        );
        port (
            clk       : in  std_logic;
            a_rst_n   : in  std_logic;
            increment : in  std_logic_vector(N - 1 downto 0);
            en        : in  std_logic;
            cntr_out  : out std_logic_vector(N - 1 downto 0)
        );
    end component;

    component mux is
        generic(
            N_input : positive
        );
        port (
            input_data : in std_logic_vector(N_input - 1 downto 0);
            control: in std_logic_vector(clog2(N_input) - 1 downto 0);
            output_data: out std_logic
        );
    end component;

    component RippleCarryAdder is
        generic (
            Nbit : positive := 8
        );
        port (
            a       : in std_logic_vector(Nbit-1 downto 0);
            b       : in std_logic_vector(Nbit-1 downto 0);
            cin     : in std_logic;
            fout    : out std_logic_vector (Nbit-1 downto 0);
            cout    : out std_logic
        );
    end component;

    component D_Flip_Flop is
        generic (
            Nbit : natural := 8
        );
        port (
            clk     : in std_logic;
            resetn  : in std_logic;
            en      : in std_logic;
            di      : in std_logic_vector(N - 1 downto 0);
            do      : out std_logic_vector(N - 1 downto 0)
        );
    end component;
begin
    rst_n <= not rst;

    counter_val <= to_integer(unsigned(output_counter));
    current_row <= counter_val / OUTPUT_DIMENSION;
    current_col <= counter_val mod OUTPUT_DIMENSION;

    en_counter <= '1' when (en = '1' and counter_val < N_OUTPUT_ELEMENTS - 1) else '0';

    counter_i: COUNTER
        generic map(
            N => N_BITS_COUNTER
        )
        port map(
            clk        => clk,
            a_rst_n    => rst_n,
            increment  => std_logic_vector(to_unsigned(1, N_BITS_COUNTER)),
            en         => en_counter,
            cntr_out   => output_counter
        );
    
    mux_istances: for i in 0 to M*M - 1 generate
        constant row_offset : integer := i / M;
        constant col_offset : integer := i mod M;
        signal mux_control : std_logic_vector(N_BITS_CONTROL_MUX - 1 downto 0);
        -- vecchia -> ordine dei bit invertito
        -- mux_control <= std_logic_vector(to_unsigned((current_row + row_offset) * N + (current_col + col_offset), N_BITS_CONTROL_MUX));
        mux_control <= std_logic_vector(to_unsigned((N*N - 1) - ((current_row + row_offset) * N + (current_col + col_offset)), N_BITS_CONTROL_MUX));
    
        mux_i: mux
        generic map(
            N_input => N*N
        )
        port map(
            input_data   => matrix,
            control      => mux_control,
            output_data  => mux_to_and(i)
        );
    end generate;

    and_istances: for i in 0 to M*M - 1 generate
        and_to_adder(i) <= mux_to_and(i) and filter((M*M - 1) - i);
    end generate;

    adders_istances: for i in 0 to M*M - 1 generate
        signal a_extended : std_logic_vector(N_BIT_OUTPUT_ELEMENT - 1 downto 0);
        a_extended <= std_logic_vector(to_unsigned(0, N_BIT_OUTPUT_ELEMENT - 1)) & and_to_adder(i);

        adder_first: if i = 0 generate
            adder_0: RippleCarryAdder
            generic map(
                Nbit    => N_BIT_OUTPUT_ELEMENT
            )
            port map(
                a       => a_extended,
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
                a       => a_extended,
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
                a       => a_extended,
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
        convolution((N_OUTPUT_ELEMENTS - i)*N_BIT_OUTPUT_ELEMENT - 1 downto (N_OUTPUT_ELEMENTS - 1 - i)*N_BIT_OUTPUT_ELEMENT) <= out_dff(i);
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
        elsif rst = '1' then
            convolution_ready <= '0';
        end if;
    end process;

end architecture;