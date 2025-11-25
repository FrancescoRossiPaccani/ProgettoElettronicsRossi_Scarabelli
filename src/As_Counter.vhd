library IEEE;
use IEEE.std_logic_1164.all;

entity As_Counter is 
    generic (
        Nbit : positive := 8
    );
    port (
        N_in        : in  std_logic_vector(Nbit - 1 downto 0);
        N_out       : out std_logic_vector(Nbit - 1 downto 0);
        clk         : in  std_logic;
        resetn      : in  std_logic
    );
end entity;

architecture ASC of As_Counter is 
    component RippleCarryAdder
        generic(
            Nbit : positive
        );
        port (
            a       : in  std_logic_vector(Nbit-1 downto 0);
            b       : in  std_logic_vector(Nbit-1 downto 0);
            cin     : in  std_logic;
            cout    : out std_logic;
            fout    : out std_logic_vector(Nbit-1 downto 0)
        );
    end component;

    
    component D_Flip_Flop
        generic(
            Nbit : positive
        );
        port(
            clk         : in  std_logic;
            resetn      : in  std_logic;
            di          : in  std_logic_vector(Nbit-1 downto 0);
            en          : in  std_logic;
            do          : out std_logic_vector(Nbit-1 downto 0)
        );
    end component;

    signal in_reg   : std_logic_vector(Nbit-1 downto 0);
    signal out_reg  : std_logic_vector(Nbit-1 downto 0);
    signal cout_aus : std_logic;
 begin
    rca: RippleCarryAdder 
    generic map(
        Nbit => Nbit
    )
    port map(
        a       => N_in,
        b       => out_reg,
        cin     => '0',
        cout    => cout_aus,
        fout    => in_reg
    );
    
    dff: D_Flip_Flop 
    generic map(
        Nbit => Nbit
    )
    port map(
        clk     => clk,
        resetn  => resetn,
        di      => in_reg,
        en      => '1',
        do      => out_reg
    );

    N_out <= out_reg;

end architecture;

