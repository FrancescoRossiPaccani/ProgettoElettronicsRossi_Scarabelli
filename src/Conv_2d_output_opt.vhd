library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Utils.all;

entity Conv_2d_output_opt is
    generic (
        N : positive := 5;
        M : positive := 3
    );
    port(
        -- shared with Conv_2d_in
        clk               : in  std_logic;
        rst               : in  std_logic;
        matrix            : in  std_logic_vector(N*N - 1 downto 0);
        filter            : in  std_logic_vector(M*M - 1 downto 0);
        en                : in  std_logic;

        -- outputs
        convolution       : out std_logic_vector(((N - M + 1)*(N - M + 1) * clog2(M*M + 1)) - 1 downto 0);
        convolution_ready : out std_logic
    );
end entity;

architecture conv_bh of Conv_2d_output_opt is

    -- Dimension of output matrix
    constant OUTPUT_DIMENSION     : natural := N - M + 1;
    constant N_OUTPUT_ELEMENTS    : natural := OUTPUT_DIMENSION * OUTPUT_DIMENSION;
    
    -- Number of bits of the counter
    constant N_BITS_COUNTER       : natural := clog2(N_OUTPUT_ELEMENTS) + 1;
    
    -- Number of bits required in order to control the multiplexers
    constant N_BITS_CONTROL_MUX   : natural := clog2(N*N);
    
    -- Number of bits required in order to represent one output element
    constant N_BIT_OUTPUT_ELEMENT : natural := clog2(M*M + 1);

    -- Signals used in order to control the multiplexers
    type muc_cntl is array (0 to M*M - 1) of std_logic_vector(N_BITS_CONTROL_MUX - 1 downto 0);
    signal mux_control : muc_cntl;

    -- Wires connected to the dffs' output
    type odff is array (0 to N_OUTPUT_ELEMENTS-1) of std_logic_vector(N_BIT_OUTPUT_ELEMENT - 1 downto 0);
    signal out_dff : odff;

    signal rst_n                 : std_logic;
    signal input_counter         : std_logic_vector(N_BITS_COUNTER - 1 downto 0);
    signal output_counter        : std_logic_vector(N_BITS_COUNTER - 1 downto 0);

    signal shift_register_output : std_logic_vector(N*N - 1 downto 0);
    signal and_to_adder          : std_logic_vector(M*M - 1 downto 0);
    signal adder_to_dff          : std_logic_vector(N_BIT_OUTPUT_ELEMENT - 1 downto 0);

    signal en_dff                : std_logic;
    signal load                  : std_logic;
    signal end_flag              : std_logic;

    signal counter_val           : natural := 0;
    -- Index of matrix used to select the right submatrix
    signal current_index         : natural := 0;

    signal output_counter_prev   : std_logic_vector(N_BITS_COUNTER - 1 downto 0);

    signal load_shr              : std_logic;
    signal en_shr                : std_logic;

    -- Costante larghezza riga output
    constant ROW_LEN             : natural := N - M + 1;

    -- Stati della FSM
    type state_t is (IDLE, CALC_WAIT, SHIFTING, WAIT_OUT);
    signal state                 : state_t;

    -- Segnale contatore per lo shift
    signal shift_cnt             : integer range 0 to M;
    -- Segnale di comodo per leggere il counter come intero
    signal curr_idx_int          : natural;

    ----------------------------------------------------------------------------
    -- Components
    ----------------------------------------------------------------------------
    component As_Counter is
        generic ( Nbit : positive := 8 );
        port (
            N_in   : in  std_logic_vector(Nbit - 1 downto 0);
            N_out  : out std_logic_vector(Nbit - 1 downto 0);
            clk    : in  std_logic;
            resetn : in  std_logic
        );
    end component;

    component SHIFT_REGISTER is
        generic( Nbit : positive := 8 );
        port(
            clk    : in  std_logic;
            resetn : in  std_logic;
            load   : in  std_logic;
            en     : in  std_logic;
            di     : in  std_logic_vector(Nbit-1 downto 0);
            q      : out std_logic_vector(Nbit-1 downto 0)
        );
    end component;

    component D_Flip_Flop is
        generic ( Nbit : natural := 8 );
        port (
            clk    : in  std_logic;
            resetn : in  std_logic;
            en     : in  std_logic;
            di     : in  std_logic_vector(Nbit - 1 downto 0);
            do     : out std_logic_vector(Nbit - 1 downto 0)
        );
    end component;

    component COUNTER_OPT is
        generic ( N_input : positive := 9 );
        port(
            clk      : in  std_logic;
            rst      : in  std_logic;
            x_in     : in  std_logic_vector(N_input - 1 downto 0);
            x_out    : out std_logic_vector(clog2(N_input + 1) - 1 downto 0);
            load     : in  std_logic;
            end_flag : out std_logic
        );
    end component;

begin

    rst_n <= not rst;

    -- Conversioni concorrenti
    counter_val <= to_integer(unsigned(output_counter)) when (en = '1' and rst = '0') else 0;
    
    curr_idx_int <= to_integer(unsigned(output_counter));

    -- Input Counter Setup
    input_counter(N_BITS_COUNTER - 1 downto 1) <= (others => '0');
    input_counter(0) <= '1' when (en = '1' and end_flag = '1') else '0';

    -- Istanza Counter
    counter_i : As_Counter
        generic map ( Nbit => N_BITS_COUNTER )
        port map (
            clk    => clk,
            resetn => rst_n,
            N_in   => input_counter,
            N_out  => output_counter
        );

    -- ATTENZIONE: Questa riga è stata commentata perché 'load_shr' 
    -- è ora pilotato dal processo 'fsm_proc'. Non possono esserci due driver.
    -- load_shr <= '1' when to_integer(unsigned(output_counter)) = 0 else '0';

    Shift_register_i: SHIFT_REGISTER
        generic map( Nbit => N*N )
        port map(
            clk    => clk,
            resetn => rst_n,
            load   => load_shr,
            en     => en_shr,
            di     => matrix,
            q      => shift_register_output
        );

    -- Logical mapping (AND array)
    and_instances : for i in 0 to M*M - 1 generate
        -- Nota: divisioni e moduli costanti (M è generic), quindi sintetizzabili come wire
        and_to_adder(i) <= shift_register_output(((i / M) * N) + (i mod M)) and filter(i);
    end generate;


    -- Optimized Adder/Counter
    c_opt : COUNTER_OPT
        generic map ( N_input => M*M )
        port map (
            clk      => clk,
            rst      => rst,
            x_in     => and_to_adder,
            x_out    => adder_to_dff,
            load     => load,
            end_flag => end_flag
        );

    -- Shift Register per l'output (DFF chain)
    dff_instances : for i in 0 to N_OUTPUT_ELEMENTS - 1 generate

        dff_last : if i = N_OUTPUT_ELEMENTS - 1 generate
            dff_i : D_Flip_Flop
                generic map ( Nbit => N_BIT_OUTPUT_ELEMENT )
                port map (
                    clk    => clk,
                    resetn => rst_n,
                    en     => en_dff,
                    di     => adder_to_dff,
                    do     => out_dff(i)
                );
        end generate;

        dff_shift : if i < N_OUTPUT_ELEMENTS - 1 generate
            dff_i : D_Flip_Flop
                generic map ( Nbit => N_BIT_OUTPUT_ELEMENT )
                port map (
                    clk    => clk,
                    resetn => rst_n,
                    en     => en_dff,
                    di     => out_dff(i+1),
                    do     => out_dff(i)
                );
        end generate;

    end generate;

    -- Output Mapping
    dff_to_output : for i in N_OUTPUT_ELEMENTS - 1 downto 0 generate
        convolution(
            ((i + 1) * N_BIT_OUTPUT_ELEMENT) - 1 downto
            (i * N_BIT_OUTPUT_ELEMENT)
        ) <= out_dff(i);
    end generate;

    en_dff <= '1' when (rst = '1' or end_flag = '1') else '0';

    -- Ready Flag Logic
    conv_process : process(clk, rst)
    begin
        if rst = '1' then
            convolution_ready <= '0';
        elsif rising_edge(clk) then
            if counter_val = N_OUTPUT_ELEMENTS then
                convolution_ready <= '1';
            else
                convolution_ready <= '0';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- FSM Control Process
    ----------------------------------------------------------------------------
    fsm_proc : process(clk, rst)
    begin
        if rst = '1' then
            state     <= IDLE;
            shift_cnt <= 0;
            load      <= '0';
            load_shr  <= '1';
            en_shr    <= '1';
            
        elsif rising_edge(clk) then
            -- Default: segnali impulsivi a 0
            load     <= '0';
            load_shr <= '0';
            en_shr   <= '0';

            case state is
                -- 1. Stato Iniziale: aspetta abilitazione
                when IDLE =>
                    if en = '1' then
                        load_shr <= '1'; -- Carica matrice iniziale
                        load     <= '1'; -- Start primo calcolo
                        state    <= CALC_WAIT;
                    end if;

                -- 2. Stato di Attesa Calcolo
                when CALC_WAIT =>
                    if end_flag = '1' then
                        -- Se non abbiamo finito l'immagine
                        if curr_idx_int < N_OUTPUT_ELEMENTS - 1 then
                            -- Passiamo allo shift
                            state <= SHIFTING;
                            
                            -- Nota: L'uso di MOD qui potrebbe rallentare il timing se ROW_LEN non è potenza di 2
                            if ((curr_idx_int + 1) mod ROW_LEN) = 0 then
                                shift_cnt <= M; -- Salto riga
                            else
                                shift_cnt <= 1; -- Shift normale
                            end if;
                        end if;
                    end if;

                -- 3. Stato di Shift attivo
                when SHIFTING =>
                    en_shr <= '1'; -- Abilita lo shift register
                    
                    if shift_cnt > 1 then
                        shift_cnt <= shift_cnt - 1;
                    else
                        -- Ultimo shift completato
                        state <= WAIT_OUT; 
                    end if;

                -- 4. Stato di transizione (per sincronizzare il load)
                when WAIT_OUT => 
                    en_shr <= '0';
                    load   <= '1'; -- Riavvia il calcolo
                    state  <= CALC_WAIT;

            end case;
        end if;
    end process;

end architecture;