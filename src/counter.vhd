library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 

entity counter is
    generic(
        N : integer
    );
    port(
        clk : in std_logic;
        resetn : in std_logic;
        do : out std_logic_vector(N-1 downto 0)
    );
end entity counter;

architecture counter_bh of counter is
    signal do_s : std_logic_vector(N-1 downto 0);
    signal rca_to_dff : std_logic_vector(N-1 downto 0);

    component dff_n is
        generic(
            N : positive
        );
        port(
            clk : in std_logic;
            resetn : in std_logic;
            di : in std_logic_vector(N-1 downto 0);
            en : in std_logic;
            do : out std_logic_vector(N-1 downto 0)
        );
    end component;

    component ripple_carry_adder is
        generic (
            N : integer
        );
        port (
            a : in std_logic_vector(N - 1 downto 0);
            b : in std_logic_vector(N - 1 downto 0);
            c_in : in std_logic;
            f : out std_logic_vector(N - 1 downto 0);
            c_out : out std_logic
        );
    end component;

begin

    do <= do_s;

    ripple_carry_adder_istance: ripple_carry_adder
        generic map(
            N => N
        )
        port map(
            a => do_s,
            b => (others => '0'),
            c_in => '1',
            f => rca_to_dff
        );
    
    dff_n_istance: dff_n
        generic map(
            N => N
        )
        port map(
            clk => clk,
            resetn => resetn,
            di => rca_to_dff,
            en => '1',
            do => do_s
        );
    
end architecture counter_bh;