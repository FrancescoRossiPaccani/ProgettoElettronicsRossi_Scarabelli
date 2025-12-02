library std;
    use std.standard.all;
    use std.textio.all;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.fixed_pkg.all;
    use ieee.math_real.all;

entity dff_n is
    generic (
        N : integer := 8
    );
    port (
        clk : in std_logic;
        resetn : in std_logic;
        di : in std_logic_vector(N-1 downto 0);
        en : in std_logic;
        do : out std_logic_vector(N-1 downto 0)
    );
end entity dff_n;

architecture dff_n_bh of dff_n is
    signal do_s : std_logic_vector (N-1 downto 0);
    
begin
        dff_n_process: process(clk, resetn)
        begin
            if resetn = '0' then
                do_s <= (others => '0');
            elsif rising_edge(clk) then
                if en = '1'then
                    do_s <= di;
                else
                    do_s <= do_s;
                end if;
            end if;

            do <= do_s;
        end process;
end architecture dff_n_bh;