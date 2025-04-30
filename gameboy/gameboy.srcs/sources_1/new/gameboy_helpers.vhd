library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.MATH_REAL.ALL;

package gameboy_helpers is

shared variable seed1, seed2 : integer := 999;
impure function rand_real(min_val, max_val : real) return real;
impure function rand_int(min_val, max_val : integer) return integer;

end gameboy_helpers;

package body gameboy_helpers is

-- This function was heavily created using this website: https://vhdlwhiz.com/random-numbers/
impure function rand_real(min_val, max_val : real) return real is
  variable r : real;
begin
  uniform(seed1, seed2, r);
  return r * (max_val - min_val) + min_val;
end function;

-- This function was heavily created using this website: https://vhdlwhiz.com/random-numbers/
impure function rand_int(min_val, max_val : integer) return integer is
  variable r : real;
begin
  uniform(seed1, seed2, r);
  return integer(
    round(r * real(max_val - min_val + 1) + real(min_val) - 0.5));
end function;



end gameboy_helpers;