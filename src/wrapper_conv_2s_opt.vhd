library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Utils.all; 

entity wrapper_conv_2d_opt is
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

    architecture wrp of wrapper_conv_2d_opt is
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

        component D_Flip_Flop is
            generic(
                Nbit : positive := 8
            );
            port(
                clk         : in std_logic;
                resetn      : in std_logic;
                di          : in std_logic_vector(Nbit-1 downto 0);
                en          : in std_logic;
                do          : out std_logic_vector(Nbit-1 downto 0)
            );

        end component;

        constant DIM_X          : natural := Nbit;
        constant DIM_Y          : natural := ((N - M + 1)*(N - M + 1) * clog2(M*M +1 ));
        signal   out_reg_x        : std_logic_vector(DIM_X - 1 downto 0);
        signal   out_reg_i_f      : std_logic;
        signal   out_reg_x_valid  : std_logic;
        signal   in_reg_y         : std_logic_vector(DIM_Y  - 1 downto 0);
        signal   in_reg_y_valid   : std_logic;
        signal   reset_aus        : std_logic;

        begin
            reset_aus <= not reset;

            reg_x: D_Flip_Flop
                generic map(
                    Nbit => DIM_X
                )
                port map(
                    clk => clk,
                    resetn => reset_aus,
                    en => '1',

                    di => x,
                    do => out_reg_x
                );  
            
            reg_if: D_Flip_Flop
                generic map(
                    Nbit => 1
                )
                port map(
                    clk     => clk,
                    resetn  => reset_aus,
                    en      => '1',

                    di(0)   => i_f,
                    do(0)   => out_reg_i_f
                );
            
             reg_x_valid: D_Flip_Flop
                generic map(
                    Nbit => 1
                )
                port map(
                    clk         => clk,
                    resetn      => reset_aus,
                    en          => '1',

                    di(0)       => x_valid,
                    do(0)       => out_reg_x_valid
                );
            
            reg_y: D_Flip_Flop
                generic map(
                    Nbit => DIM_Y
                )
                port map(
                    clk => clk,
                    resetn => reset_aus,
                    en => '1',

                    di => in_reg_y,
                    do => y
                );

            reg_y_valid: D_Flip_Flop
                generic map(
                    Nbit => 1
                )
                port map(
                    clk     => clk,
                    resetn  => reset_aus,
                    en      => '1',

                    di(0)   => in_reg_y_valid,
                    do(0)   => y_valid
                );
            conv: Conv_2d_opt
                generic map(
                    N      => N,
                    M      => M,
                    Nbit   => Nbit
                )
                port map(
                    clk         => clk,
                    reset       => reset,

                    x_valid     => out_reg_x_valid,
                    i_f         => out_reg_i_f,
                    x           => out_reg_x,

                    y           => in_reg_y,
                    y_valid     => in_reg_y_valid
                );
        

    end architecture;