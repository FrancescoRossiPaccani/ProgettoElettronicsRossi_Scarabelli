library IEEE;
use IEEE.std_logic_1164.all;

entity D_Flip_Flop is
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

end entity;

architecture DFF of D_Flip_Flop is
    signal in_aus : std_logic_vector(Nbit-1 downto 0);
    signal do_aus : std_logic_vector(Nbit-1 downto 0);

    begin
    p_DFF: process(clk, resetn)
    begin
        if resetn = '0' then
            do_aus <= (others => '0'); 
        elsif rising_edge(clk) then
            do_aus <= in_aus;
        end if;
    end process;

    in_aus <= di when en = '1' else do_aus;
    do <= do_aus;
end architecture ; -- DFF