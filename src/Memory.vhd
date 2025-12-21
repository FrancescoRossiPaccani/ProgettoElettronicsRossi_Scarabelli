library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Utils.all; 

entity Memory is
    generic(
        Ncell   : positive := 9;     -- dimenzione memoria Ncell = N*N
        Nbit_in : positive := 8      -- numero di bit in ingresso (sempre 8 date le specifiche di progetto)
    );
    port(
        clk         : in  std_logic;
        resetn      : in  std_logic;
        en          : in  std_logic;  -- enabler 
        selector    : in  std_logic_vector(clog2((Ncell + Nbit_in -1)/Nbit_in)-1 downto 0); -- selettore di memoria
        d_in        : in  std_logic_vector(Nbit_in-1 downto 0); -- dati in ingresso
        d_out       : out std_logic_vector(Ncell-1   downto 0)  -- dati in uscita
    );
end entity;

architecture MEM of Memory is

    component D_Flip_Flop
        generic (
            Nbit : positive
        );
        port(
            clk         : in std_logic;
            resetn      : in std_logic;
            di          : in std_logic_vector(Nbit-1 downto 0);
            en          : in std_logic;
            do          : out std_logic_vector(Nbit-1 downto 0)
        );

    end component;
    constant SEL_DIM    : natural := 1 + (Ncell + Nbit_in - 1)/Nbit_in; -- massimo valore del selettore 

    signal en_i         : std_logic_vector(Ncell-1 downto 0);
    signal sel_int      : natural range 0 to SEL_DIM ;

    begin 
        sel_int <= to_integer(unsigned(selector)) when en = '1' else SEL_DIM; -- assegnamento al selettore, per protezione viene posto al valore massimo che non viene usato quando il componente spento (en = '0') 
        
        -- Processo di selezione di memorie
        enabler: process(sel_int, en)
            begin
                if en = '0' then
                    en_i <= (others => '0');
                elsif en = '1' then
                    en_i <= (others => '0');
                    for i in sel_int * Nbit_in to sel_int * Nbit_in + Nbit_in-1 loop -- attivo le Nbit in memorie da 1 bit che devono salvare il dato in ingresso
                        exit when i >= Ncell;      -- In caso di sforo (per esempio quando devo salvare un numero di bit in ingresso < nbit ovvero quando il numero di elementi da salvare != multiplo inero di Nbit in) 
                        en_i(i) <= '1';
                    end loop;
                end if;
            end process;
    
        -- Generazione memorie
        g_DFF_i:  for i in 0 to ((Ncell + Nbit_in - 1)/Nbit_in)-1 generate
            g_DFF_j: for j in 0 to Nbit_in-1 generate
                        g_if: if i*Nbit_in + j < Ncell generate --Se non sforo (sempre caso di numero di elementi da salvare != k * Nbit_in con k intero)
                            i_DFF: D_Flip_Flop
                                        generic map(
                                            Nbit => 1
                                        )
                                        port map(
                                            clk => clk,
                                            resetn => resetn,
                                            en => en_i(i*Nbit_in + j),  
                                            di => d_in(j downto j),     -- poichè vuole un std_logic_vector di 1 elem 
                                            do => d_out(i*Nbit_in + j downto i*Nbit_in + j)
                                        );
                        end generate g_if;
            end generate;
        end generate;
end architecture;