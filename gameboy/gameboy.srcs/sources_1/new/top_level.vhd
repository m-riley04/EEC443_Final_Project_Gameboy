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
           BTNU : in STD_LOGIC;
           BTNL : in STD_LOGIC;
           BTNR : in STD_LOGIC;
           BTND : in STD_LOGIC;
           SW : in STD_LOGIC_VECTOR (15 downto 0);
           AN : out STD_LOGIC_VECTOR (7 downto 0);
           CA : out STD_LOGIC_VECTOR (6 downto 0);
           LED : out STD_LOGIC_VECTOR (15 downto 0));
end top_level;

architecture Behavioral of top_level is
    --------------------------------------------------------------------------
    component rock_paper_scissors is
        port (
            clk       : in  std_logic;
            btn_l     : in  std_logic;
            btn_u     : in  std_logic;
            btn_r     : in  std_logic;
            AN        : out std_logic_vector(7 downto 0);
            CA        : out std_logic_vector(6 downto 0);
            LED       : out std_logic_vector(15 downto 0)
        );
    end component;

    signal an_rpc  : std_logic_vector(7 downto 0);
    signal ca_rpc  : std_logic_vector(6 downto 0);
    signal led_rpc : std_logic_vector(15 downto 0);
begin
    -- Rock / Paper / Scissors instance
    game_rpc : rock_paper_scissors
        port map (
            clk   => CLK100MHZ,
            btn_l => BTNL,
            btn_u => BTNU,
            btn_r => BTNR,
            AN    => an_rpc,
            CA    => ca_rpc,
            LED   => led_rpc
        );

    -- Game-select on SW(15) (0 = active, 1 = blank)
    with SW(15) select
        AN  <= an_rpc  when '0', (others=>'1') when others;
    with SW(15) select
        CA  <= ca_rpc  when '0', (others=>'1') when others;
    with SW(15) select
        LED <= led_rpc when '0', (others=>'0') when others;
end Behavioral;

