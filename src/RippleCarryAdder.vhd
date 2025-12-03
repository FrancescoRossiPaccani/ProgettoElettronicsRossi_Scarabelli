library IEEE;
use IEEE.std_logic_1164.all;

entity RippleCarryAdder is 
    generic (
        Nbit : positive := 8
    );
    port (
        a       : in std_logic_vector(Nbit-1 downto 0);
        b       : in std_logic_vector(Nbit-1 downto 0);
        cin     : in std_logic;
        cout    : out std_logic;
        fout    : out std_logic_vector(Nbit-1 downto 0)
    );
end entity;

architecture RCA of RippleCarryAdder is
    
    component FullAdder 
        port (
            a : in std_logic;
            b : in std_logic;
            cin : in std_logic;
            cout : out std_logic;
            s : out std_logic
        );
    end component;

    signal c_s  : std_logic_vector(Nbit - 1  downto 0);

begin

    g_FullAdder: for i in 0 to Nbit-1 generate
        g_FIRST: if i = 0 generate
            i_FullAdder: FullAdder 
            port map (
                a       => a(i),
                b       => b(i),
                cin     => cin,
                cout    => c_s(i),
                s       => fout(i)
            );
        end generate; 
        g_INTERNAL: if i > 0 and i < Nbit generate
            i_FullAdder: FullAdder
             port map (
                a       => a(i),
                b       => b(i),
                cin     => c_s(i-1),
                cout    => c_s(i),
                s       => fout(i)
            );
        end generate;
    end generate;

    cout <= c_s(Nbit - 1);
end architecture; 