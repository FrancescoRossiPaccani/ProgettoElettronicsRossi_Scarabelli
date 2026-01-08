library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Utils.all; 

entity Memory is
    generic(
        Ncell   : positive := 9;     -- Memory dimension
        Nbit_in : positive := 8      -- Number of input bits 
    );
    port(
        clk         : in  std_logic;
        resetn      : in  std_logic;
        en          : in  std_logic;  -- enabler 
        selector    : in  std_logic_vector(clog2((Ncell + Nbit_in -1)/Nbit_in)-1 downto 0); -- memory selector
        d_in        : in  std_logic_vector(Nbit_in-1 downto 0); -- input data
        d_out       : out std_logic_vector(Ncell-1   downto 0)  -- output data
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
    constant SEL_DIM    : natural := 1 + (Ncell + Nbit_in - 1)/Nbit_in; -- max selecto value 
 

    signal en_i         : std_logic_vector(Ncell-1 downto 0);
    signal sel_int      : natural range 0 to SEL_DIM ;

    begin 
        sel_int <= to_integer(unsigned(selector)) when en = '1' else SEL_DIM; -- selector assignment, set to a safe unused maximum value when the component is disabled (en = '0') 

        --  Memories selections process
         enabler: process(sel_int, en)
             begin
                 if en = '0' then
                     en_i <= (others => '0');
                 elsif en = '1' then
                     en_i <= (others => '0');
                     for i in 0 to  Nbit_in-1 loop -- Enables the Nbit 1-bit memories that store the input data.
                        if (sel_int * Nbit_in + i) < Ncell then
                            en_i(sel_int * Nbit_in + i) <= '1';
                        end if;
                     end loop;
                 end if;
             end process;
    
        -- Memories generations
        g_DFF_i:  for i in 0 to ((Ncell + Nbit_in - 1)/Nbit_in)-1 generate
            g_DFF_j: for j in 0 to Nbit_in-1 generate
                        g_if: if i*Nbit_in + j < Ncell generate --If no overflow occurs (i.e. when the number of elements to be stored is not equal to k · Nbit_in, with integer k)
                            i_DFF: D_Flip_Flop
                                        generic map(
                                            Nbit => 1
                                        )
                                        port map(
                                            clk => clk,
                                            resetn => resetn,
                                            en => en_i(i*Nbit_in + j),  
                                            di => d_in(j downto j),     -- since it requires a std_logic_vector of 1 elem
                                            do => d_out(i*Nbit_in + j downto i*Nbit_in + j)
                                        );
                        end generate g_if;
            end generate;
        end generate;
end architecture;