library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Conv_2d_input is
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
    );
end entity;

architecture C2D of Conv_2d_input is

end architecture;