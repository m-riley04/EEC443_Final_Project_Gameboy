library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

package display_helpers is

constant hyphen : integer := 45;

constant dig0 : integer := 48;
constant dig1 : integer := 49;
constant dig2 : integer := 50;
constant dig3 : integer := 51;
constant dig4 : integer := 52;
constant dig5 : integer := 53;
constant dig6 : integer := 54;
constant dig7 : integer := 55;
constant dig8 : integer := 56;
constant dig9 : integer := 57;

constant letA : integer := 65;
constant letB : integer := 66;
constant letC : integer := 67;
constant letD : integer := 68;
constant letE : integer := 69;
constant letF : integer := 70;
constant letG : integer := 71;
constant letH : integer := 72;
constant letI : integer := 73;
constant letJ : integer := 74;
constant letK : integer := 75;
constant letL : integer := 76;
constant letM : integer := 77;
constant letN : integer := 78;
constant letO : integer := 79;
constant letP : integer := 80;
constant letQ : integer := 81;
constant letR : integer := 82;
constant letS : integer := 83;
constant letT : integer := 84;
constant letU : integer := 85;
constant letV : integer := 86;
constant letW : integer := 87;
constant letX : integer := 88;
constant letY : integer := 89;
constant letZ : integer := 90;

function seg_pat(c : character) return std_logic_vector;
function rpc_ch_choice(i : integer) return character;
function rpc_ch_result(i : integer) return character;
function hl_ch_result(i : integer) return character;

end display_helpers;

package body display_helpers is

function seg_pat(c : character) return std_logic_vector is
    variable abcd    : std_logic_vector(6 downto 0);
begin
    case c is
        when '0' => abcd := "0000001";
        when '1' => abcd := "1001111";
        when '2' => abcd := "0010010";
        when '3' => abcd := "0000110";
        when '4' => abcd := "1001100";
        when '5' => abcd := "0100100";
        when '6' => abcd := "0100000";
        when '7' => abcd := "0001111";
        when '8' => abcd := "0000000";
        when '9' => abcd := "0000100";
        when 'A' => abcd := "0001000";
        when 'C' => abcd := "0110001";
        when 'E' => abcd := "0110000";
        when 'H' => abcd := "1001000";
        when 'L' => abcd := "1110001";
        when 'O' => abcd := "0000001";
        when 'P' => abcd := "0011000";
        when 'R' => abcd := "1111010";  -- small "r" shape
        when 'S' => abcd := "0100100";
        when 'T' => abcd := "1110000";
        when 'W' => abcd := "1100011";  -- very rough w
        when '-' => abcd := "1111110";
        when others => abcd := (others=>'1');  -- blank
    end case;
    
    return abcd;
end function;

function rpc_ch_choice(i : integer) return character is
begin
    case i is
        when 0      => return 'R';
        when 1      => return 'P';
        when 2      => return 'S';
        when others => return '-';
    end case;
end;

function rpc_ch_result(i : integer) return character is
begin
    case i is
        when 0      => return 'T';       -- tie
        when 1      => return 'W';       -- win
        when 2      => return 'L';       -- lose
        when others => return '-';
    end case;
end;

function hl_ch_result(i : integer) return character is
begin
    case i is
        when 0      => return 'L';       -- lower
        when 1      => return 'W';       -- win
        when 2      => return 'H';       -- higher
        when others => return '-';
    end case;
end;

end package body;
