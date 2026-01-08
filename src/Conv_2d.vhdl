    library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use work.Utils.all; 

    entity Conv_2d is
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
    end entity;

    architecture C2D of Conv_2d is
        component Conv_2d_input 
            generic(
                N       : positive := 5;
                M       : positive := 3; 
                Nbit    : positive := 8
            );
            port(
                -- -- after y_valid goes high reset everything (used as handshake)
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
        end component;

        component  Conv_2d_output is
            generic(
                N : positive := 5;
                M : positive := 3
            );
            port(
                clk                 : in  std_logic;
                rst                 : in  std_logic;
                matrix              : in  std_logic_vector(N*N - 1 downto 0);
                filter              : in  std_logic_vector(0 to M*M - 1 );
                en                  : in  std_logic;
                convolution         : out std_logic_vector(((N - M + 1)*(N - M + 1) * clog2(M*M + 1)) - 1 downto 0 );
                convolution_ready   : out std_logic
        );

        end component;

        signal   en_exe         : std_logic;
        signal   filter_link    : std_logic_vector(M*M - 1 downto 0);
        signal   matrix_link    : std_logic_vector(N*N - 1 downto 0); 
        
        signal   reset_in       : std_logic;
        signal   reset_out      : std_logic;

        signal   y_valid_aus    : std_logic; -- internal signal used for loopback and pulse generation
        signal   y_valid_prev   : std_logic; -- value of y_valid_aus at the previous clock
        signal   y_pulse        : std_logic; -- clock pulse generated on the rising edge of y_valid_aus
        signal   y_reset        : std_logic; -- synchronized reset signal, registered (previus clock) copy of y_pulse (used to reset Conv_2d_input)
        
        signal   x_valid_aus    : std_logic;
        
        begin
            -- Pulse generator for y_valid
            y_valid_proc: process(clk, reset)
            begin
                if reset = '1' then
                    y_valid_prev  <= '0'; 
                    y_pulse       <= '0';
                    y_reset      <= '0';
                elsif rising_edge(clk) then
                    if (y_valid_aus = '1') and (y_valid_prev = '0') then
                        y_pulse <= '1';
                    else
                        y_pulse <= '0';
                    end if; 
                    -- store the current value for comparison at the next clock 
                    y_valid_prev <= y_valid_aus;
                    y_reset      <= y_pulse;
                end if;
            end process;

            y_valid <= y_pulse;
            
            reset_in  <= reset or y_reset;  
            reset_out <= reset or not en_exe ; 

            x_valid_aus <= x_valid when (en_exe = '0' and y_valid_aus = '0') else '0'; -- non posso avere stati validi finchè l'esecuzione non è terminata 

            C_INP:  Conv_2d_input
                        generic map(
                            N    => N,
                            M    => M,
                            Nbit => Nbit
                        )
                        port map( 
                            clk                 => clk,
                            reset               => reset_in, 
                            en_execution        => en_exe,
                            filter_out          => filter_link,
                            matrix_out          => matrix_link,
                            x_valid             => x_valid_aus,
                            i_f                 => i_f,
                            x                   => x -- ,
                            -- stato               => status
                        );

            C_OUT: Conv_2d_output
                        generic map(
                            N                   => N,
                            M                   => M
                        )
                        port map(
                            clk                 => clk,
                            rst                 => reset_out,
                            matrix              => matrix_link,
                            filter              => filter_link,
                            convolution         => y,
                            en                  => en_exe,
                            convolution_ready   => y_valid_aus
                        );    
        
    end architecture;