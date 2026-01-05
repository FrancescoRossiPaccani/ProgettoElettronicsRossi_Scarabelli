library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.Utils.all;

entity counter_opt is
    generic (
        N_input : positive := 9
    );
    port(
        clk                 : in  std_logic;
        rst                 : in  std_logic;
        x_in                : in std_logic_vector(N_input downto 0);
        x_out               : out std_logic_vector(clog2(N_input + 1) - 1 downto 0);
        load                : in std_logic;
        end_flag            : out std_logic
    );
end entity;

architecture counter_opt_bh of counter_opt is
    constant N_BIT_OUTPUT   : natural := clog2(N_input + 1);

    signal counter_output           : std_logic_vector(N_BIT_OUTPUT - 1 downto 0);
    signal shift_register_output    : std_logic_vector(N_input - 1 downto 0);

    component SHIFT_REGISTER is
        generic(
            Nbit : positive := 8
        );
        port(
            clk    : in  std_logic;
            resetn : in  std_logic;
            load   : in  std_logic;
            di     : in  std_logic_vector(Nbit-1 downto 0);
            q      : out std_logic_vector(Nbit-1 downto 0)
        );
    end component;

    component As_Counter is
        generic (
            Nbit : positive := 8
        );
        port (
            N_in        : in  std_logic_vector(Nbit - 1 downto 0);
            N_out       : out std_logic_vector(Nbit - 1 downto 0);
            clk         : in  std_logic;
            resetn      : in  std_logic
        );
    end component;

begin

    Shift_register_i: SHIFT_REGISTER
        generic map(
            Nbit => N_input
        )
        port map(
            clk => clk,
            resetn => rst,
            load => load,
            di => x_in,
            q => shift_register_output
        );

    As_Counter_output: As_Counter
        generic map(
            Nbit => N_BIT_OUTPUT
        )
        port map(
            N_in        => shift_register_output(0),
            N_out       => x_out,
            clk         => clk,
            resetn      => rst
        );

    As_Counter_states: As_counter
        generic map(
            Nbit => N_BIT_OUTPUT
        )
        port map(
            N_in        => (0 => (not load), others => '0'),
            N_out       => counter_output,
            clk         => clk,
            resetn      => rst
        );

    count_out_process: process(clk, rst)
    begin
        if rst = '1' then
            end_flag <= '0';
        elsif rising_edge(clk) then
            if(to_integer(unsigned(counter_output)) = N_input) then
                end_flag <= '1';
            end if;
        end if;
    end process;

end architecture;