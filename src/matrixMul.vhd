library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 

entity matrixMul is
    generic(
        N : integer
        -- numberOfBits : integer := log2(N*N) + 1
    );
    port(
        a : in std_logic_vector(N*N - 1 downto 0);
        b : in std_logic_vector(N*N - 1 downto 0);
        -- c : out std_logic_vector(numberOfBits - 1 downto 0)
        c : out std_logic_vector(3 downto 0)
    );
end entity;

architecture matrixMul_bh of matrixMul is

begin

end architecture;