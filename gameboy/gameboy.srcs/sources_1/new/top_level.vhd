----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Riley Meyerkorth, Nicholas Holmes
-- 
-- Create Date: 04/29/2025 06:59:51 PM
-- Design Name: Gameboy
-- Module Name: top_level - Behavioral
-- Project Name: Gameboy
-- Target Devices: Nexys 4
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    Port ( CLK100MHZ : in STD_LOGIC;
           BTNC : in STD_LOGIC;
           SW : in STD_LOGIC_VECTOR (15 downto 0);
           AN : out STD_LOGIC_VECTOR (7 downto 0);
           CA : out STD_LOGIC_VECTOR (6 downto 0);
           LED : out STD_LOGIC_VECTOR (15 downto 0));
end top_level;

architecture Behavioral of top_level is

begin


end Behavioral;
