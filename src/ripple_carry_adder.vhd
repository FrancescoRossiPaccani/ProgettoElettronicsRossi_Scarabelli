library std;
    use std.standard.all;
    use std.textio.all;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.fixed_pkg.all;
    use ieee.math_real.all;

entity ripple_carry_adder is
    generic (
        N : integer := 8
    );

    port (
        a : in std_logic_vector(N - 1 downto 0);
        b : in std_logic_vector(N - 1 downto 0);
        c_in : in std_logic;
        f : out std_logic_vector(N - 1 downto 0);
        c_out : out std_logic
    );
end entity ripple_carry_adder;

architecture ripple_carry_adder_behaviour of ripple_carry_adder is
    component full_adder is
        port (
            a : in std_logic;
            b : in std_logic;
            cin : in std_logic;
            cout : out std_logic;
            s : out std_logic
        );
    end component;

    signal c_interconnessione: std_logic_vector(N downto 0);
    
    begin
        c_interconnessione(0) <= c_in;

        generate_adders: for i in 0 to N-1 generate
            full_adder_i : full_adder
            port map(
                a => a(i),
                b => b(i),
                cin => c_interconnessione(i),
                cout => c_interconnessione(i+1),
                s => f(i)
            );
        end generate generate_adders;

        c_out <= c_interconnessione(N);
end architecture ripple_carry_adder_behaviour;