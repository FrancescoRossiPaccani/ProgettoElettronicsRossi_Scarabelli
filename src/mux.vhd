library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Utils.all;

entity mux is
    generic(
        -- number of inputs
        N_input : positive
    );
    port (
        input_data      : in std_logic_vector(N_input - 1 downto 0);
        control         : in std_logic_vector(clog2(N_input) - 1 downto 0);
        output_data     : out std_logic
    );
end entity;

architecture mux_bh of mux is
begin
    output_data <= input_data(to_integer(unsigned(control)));
end architecture;