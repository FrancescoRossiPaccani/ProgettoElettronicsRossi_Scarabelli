library IEEE;
use IEEE.std_logic_1164.all;

-- this shift register load the data on the rising edge of the clock if load = '1' and shift the previus loaded data (after the rising edge of the clock) if load = '0'

entity SHIFT_REGISTER is
    generic(
        Nbit : positive := 8
    );
    port(
        clk    : in  std_logic;
        resetn : in  std_logic;
        load   : in  std_logic;
        en     : in  std_logic; 
        di     : in  std_logic_vector(Nbit-1 downto 0);
        q      : out std_logic_vector(Nbit-1 downto 0)
    );
end entity;

architecture rtl of SHIFT_REGISTER is
    signal q_reg : std_logic_vector(Nbit-1 downto 0);
begin
    process(clk, resetn)
    begin
        if resetn = '0' then
            q_reg <= (others => '0');

        elsif rising_edge(clk) then
            if en = '1' then
                if load = '1' then
                    q_reg <= di;  --load
                else
                    q_reg <= '0' & q_reg(Nbit-1 downto 1); -- right shift
                end if;
            else 
                    q_reg <= q_reg;
            end if;
        end if;
    end process;

    q <= q_reg;

end architecture;
