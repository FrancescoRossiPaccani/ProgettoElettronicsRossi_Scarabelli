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
            y            : out std_logic_vector(((N - M + 1)*(N - M + 1) * clog2(M*M)) - 1 downto 0);
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
                -- quando y valid va ad 1 resetto tutto da usare come handshake
                -- condivise con modulo Conv_2d_output
                clk          : in std_logic;
                reset        : in std_logic;
                en_execution : out std_logic;
                filter_out   : out std_logic_vector(M*M - 1 downto 0);
                matrix_out   : out std_logic_vector(N*N - 1 downto 0);
                -- uniche   
                x_valid      : in std_logic;
                i_f          : in std_logic;
                x            : in std_logic_vector(Nbit-1 downto 0);

                --debug 
                stato        : out std_logic_vector( clog2((M*M+Nbit-1)/Nbit + (N*N+Nbit-1)/Nbit)-1 downto 0) 
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
        constant Nbit_out       : natural := clog2(M*M);
        signal   en_exe         : std_logic;
        signal   filter_link    : std_logic_vector(M*M - 1 downto 0);
        signal   matrix_link    : std_logic_vector(N*N - 1 downto 0); 
        signal   status         : std_logic_vector( clog2((M*M+Nbit-1)/Nbit + (N*N+Nbit-1)/Nbit)-1 downto 0);
        signal   reset_in       : std_logic;
        signal   reset_out      : std_logic;
        signal   y_valid_aus    : std_logic;
        signal   y_reset        : std_logic;
        begin

            reset_in  <= reset; -- or y_reset;
            reset_out <= reset or not en_exe ; 

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
                            x_valid             => x_valid,
                            i_f                 => i_f,
                            x                   => x,
                            stato               => status
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

        y_valid <= y_valid_aus;
        
    end architecture;