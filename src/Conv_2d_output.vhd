library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Utils.all; 

entity Conv_2d_output is
    generic(
        N    : positive := 5;
        M    : positive := 3;
        Nbit_out : positive := 4 
    );
    port(
        -- clock port
        clk : in std_logic;
        -- reset input -> attivo alto
        rst : in std_logic;
        -- input matrix (N*N elements, 1 bit each)
        matrix : in std_logic_vector(N*N - 1 downto 0);
        -- filter matrix (M*M elements, 1 bit each)
        filter : in std_logic_vector(M*M - 1 downto 0);
        
        convolution : out std_logic_vector(((N - M + 1)*(N - M + 1) * clog2(M*M)) - 1 downto 0);
        -- enabler
        en : in std_logic 
    );
end entity;

architecture conv_bh of Conv_2d_output is
    -- size of output matrix
    constant convolutionSize : integer := N - M + 1;
    -- number of output matrix's elements
    constant output_elements : integer := convolutionSize * convolutionSize;

    type slv is array (natural range <>) of std_logic_vector(Nbit_out - 1 downto 0);

    constant ADDR_BITS          : natural := clog2(N*N);
    constant OUT_CNT_BITS       : natural := clog2((N-M+1)*(N-M+1));
    -- segnali
    signal convolution_s        : std_logic_vector((output_elements * Nbit_out) - 1 downto 0);
    signal output_counter       : std_logic_vector(OUT_CNT_BITS - 1 downto 0);
    signal rst_n                : std_logic;
    signal and_to_adder         : std_logic_vector(M*M - 1 downto 0);
    signal mux_to_and           : std_logic_vector(M*M - 1 downto 0);
    signal adder_out_adder_in   : slv(M*M - 2 downto 0);
    signal adder_to_dff         : std_logic_vector(Nbit_out - 1 downto 0);
    signal en_dff               : std_logic_vector(output_elements - 1 downto 0);

    signal counter_val          : integer := 0;
    signal current_row          : integer := 0;
    signal current_col          : integer := 0;

    signal count_in             : std_logic_vector(OUT_CNT_BITS - 1 downto 0);

    -- n bit counter component
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

    -- mux n inputs
    component mux is
        generic(
            N_input : integer
        );
        port (
            input_data : in std_logic_vector(N_input - 1 downto 0);
            control: in std_logic_vector(ADDR_BITS - 1 downto 0);
            output_data: out std_logic
        );
    end component;

    -- n bit adder
    component ripple_carry_adder is
        generic (
            N : integer
        );
        port (
            a : in std_logic_vector(N - 1 downto 0);
            b : in std_logic_vector(N - 1 downto 0);
            c_in : in std_logic;
            f : out std_logic_vector(N - 1 downto 0);
            c_out : out std_logic
        );
    end component;

    -- n bit dff
    component dff_n is
        generic (
            N : integer
        );
        port (
            clk : in std_logic;
            resetn : in std_logic;
            di : in std_logic_vector(N-1 downto 0);
            en : in std_logic;
            do : out std_logic_vector(N-1 downto 0)
        );
    end component;
begin
    -- convolution <= convolution_s;
    rst_n <= not rst;

    -- counting iterations -> one iteration for each output element
    -- ** AS_COUNTER

        count_in(OUT_CNT_BITS -1 downto 1) <= (others => '0');
        count_in(0) <= en;

    counter_instance: As_Counter
        generic map(
            Nbit => OUT_CNT_BITS
        )
        port map(
            clk => clk,
            resetn => rst_n,
            N_out => output_counter,
            N_in => count_in
        );
    
    -- compute current row and column index
    counter_val <= to_integer(unsigned(output_counter));
    current_row <= counter_val / convolutionSize;
    current_col <= counter_val mod convolutionSize;

    -- multiplexers to select the sliding window on the main matrix
    muxs_instances: for i in 0 to M*M - 1 generate
        constant row_offset : integer := i / M;
        constant col_offset : integer := i mod M;
        signal mux_ctrl : std_logic_vector(ADDR_BITS - 1 downto 0);
        
        mux_ctrl <= std_logic_vector(to_unsigned((current_row + row_offset) * N + (current_col + col_offset), ADDR_BITS));

        mux_i: mux
            generic map(
                N_input => N*N
            )
            port map(
                input_data => matrix,
                control => mux_ctrl,
                output_data => mux_to_and(i)
            );
    end generate;

    -- and operation between element of matrix and element of filter
    and_instances: for i in 0 to M*M - 1 generate
        and_to_adder(i) <= mux_to_and(i) and filter(i);
    end generate;

    -- adders
    adders_instances: for i in 0 to M*M - 1 generate
        signal computed_a : std_logic_vector(Nbit_out - 1 downto 0);
        computed_a <= std_logic_vector(to_unsigned(0, Nbit_out - 1)) & and_to_adder(i);
        adder_first: if i = 0 generate
            adder_i: ripple_carry_adder
            generic map(
                N => Nbit_out
            )
            port map(
                a => computed_a,
                b => (others => '0'),
                c_in => '0',
                f => adder_out_adder_in(i),
                c_out => open
            );
        end generate;

        adder_middle: if i > 0 and i < M*M - 1 generate
            adder_i: ripple_carry_adder
            generic map(
                N => Nbit_out
            )
            port map(
                a => computed_a,
                b => adder_out_adder_in(i-1),
                c_in => '0',
                f => adder_out_adder_in(i),
                c_out => open
            );
        end generate;

        adder_last: if i = M*M - 1 generate
            adder_i: ripple_carry_adder
            generic map(
                N => Nbit_out
            )
            port map(
                a => computed_a,
                b => adder_out_adder_in(i-1),
                c_in => '0',
                f => adder_to_dff,
                c_out => open
            );
        end generate;

    end generate;

    -- dff
    dff_istances: for i in 0 to output_elements - 1 generate
        dff_i: dff_n
            generic map(
                N => Nbit_out
            )
            port map(
                clk => clk,
                resetn => rst_n,
                di => adder_to_dff,
                en =>  en_dff(i),
                do => convolution((i+1)*Nbit_out - 1 downto i*Nbit_out)
            );
    end generate;

    conv_process : process(clk, rst)
    begin
        if rst = '1' then
            -- convolution_s <= (others => '0');
            en_dff <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                if to_integer(unsigned(output_counter)) < output_elements then
                    for i in 0 to output_elements-1 loop
                        if i = to_integer(unsigned(output_counter)) then
                            en_dff(i) <= '1';
                        else
                            en_dff(i) <= '0';
                        end if;
                    end loop;
                else
                    en_dff <= (others => '0');
                end if;
            end if;
        end if;
    end process;

end architecture;
