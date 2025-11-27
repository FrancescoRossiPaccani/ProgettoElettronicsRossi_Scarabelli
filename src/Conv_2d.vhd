library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Conv_2d is
    generic(
        Nsquare : positive := 25;
        Msquare : positive := 9; 
        Nbit    : positive := 8
    );
    port(
        clk         : in std_logic;
        reset       : in std_logic;
        x_valid     : in std_logic;
        i_f         : in std_logic;
        x           : 
    );
end entity;