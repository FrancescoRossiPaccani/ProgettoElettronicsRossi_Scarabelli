library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package Utils is
    -- funzione per calcolare il numero di bit necessari
    function clog2(x: positive) return natural;
end package;

package body Utils is
    function clog2(x: positive) return natural is
        variable tmp: natural := x-1;
        variable res: natural := 0;
    begin
        while tmp > 0 loop
            tmp := tmp / 2;
            res := res + 1;
        end loop;
        return res;
    end function;
end package body;
