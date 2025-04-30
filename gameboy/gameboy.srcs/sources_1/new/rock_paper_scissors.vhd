--------------------------------------------------------------------------------
-- Rock-Paper-Scissors game for the Nexys-4 "Gameboy"
-- (EECS 443 - Digital Logic - 2025)
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use WORK.display_helpers.all;               -- segment patterns

entity rock_paper_scissors is
    port (
        clk       : in  std_logic;          -- 100 MHz
        btn_l     : in  std_logic;          -- ROCK     (BTNL)
        btn_u     : in  std_logic;          -- PAPER    (BTNU)
        btn_r     : in  std_logic;          -- SCISSORS (BTNR)
        AN        : out std_logic_vector(7 downto 0);
        CA        : out std_logic_vector(6 downto 0);
        LED       : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of rock_paper_scissors is
    ---------------------------------------------------------------------------
    -- game state
    ---------------------------------------------------------------------------
    type state_t is (WAIT_INPUT, SHOW_COMP, SHOW_RES);
    signal state        : state_t := WAIT_INPUT;

    signal user_choice  : integer range 0 to 2 := 0;  -- 0 = R, 1 = P, 2 = S
    signal comp_choice  : integer range 0 to 2 := 0;
    signal result       : integer range 0 to 2 := 0;  -- 0 = tie, 1 = win, 2 = lose

    ---------------------------------------------------------------------------
    -- 17-bit Fibonacci LFSR  (poly x^17 + x^14 + 1)
    ---------------------------------------------------------------------------
    signal lfsr : std_logic_vector(16 downto 0) := "11010101100111010";
    signal fb   : std_logic;

    ---------------------------------------------------------------------------
    -- single-clock synchronisers for buttons
    ---------------------------------------------------------------------------
    signal sync_l, sync_u, sync_r : std_logic_vector(1 downto 0) := (others=>'0');
    signal hit_l,  hit_u,  hit_r  : std_logic;

    ---------------------------------------------------------------------------
    -- half-second timer  (50 000 000 clocks @ 100 MHz)
    ---------------------------------------------------------------------------
    constant HALF_SEC : unsigned(25 downto 0) := to_unsigned(50_000_000, 26);
    signal   t_cnt    : unsigned(25 downto 0) := (others=>'0');

    ---------------------------------------------------------------------------
    -- ***  helper functions  ***  (must be in declarative part!)
    ---------------------------------------------------------------------------
    function ch_choice(i : integer) return character is
    begin
        case i is
            when 0      => return 'R';
            when 1      => return 'P';
            when 2      => return 'S';
            when others => return '-';
        end case;
    end;

    function ch_result(i : integer) return character is
    begin
        case i is
            when 0      => return 'T';       -- tie
            when 1      => return 'W';       -- win
            when 2      => return 'L';       -- lose
            when others => return '-';
        end case;
    end;
begin
    ----------------------------------------------------------------------------
    -- LFSR update (runs every clock)
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            fb   <= lfsr(16) xor lfsr(13);          -- taps 17 & 14
            lfsr <= lfsr(15 downto 0) & fb;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- button edge detectors
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            sync_l <= sync_l(0) & btn_l;
            sync_u <= sync_u(0) & btn_u;
            sync_r <= sync_r(0) & btn_r;

            hit_l  <= sync_l(0) and not sync_l(1);
            hit_u  <= sync_u(0) and not sync_u(1);
            hit_r  <= sync_r(0) and not sync_r(1);
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- main FSM
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            case state is
            --------------------------------------------------------------------
            when WAIT_INPUT =>
                t_cnt <= (others=>'0');
                if hit_l='1' or hit_u='1' or hit_r='1' then
                    if    hit_l='1' then user_choice <= 0;          -- R
                    elsif hit_u='1' then user_choice <= 1;          -- P
                    else                 user_choice <= 2;          -- S
                    end if;
                    comp_choice <= to_integer(unsigned(lfsr(1 downto 0))) mod 3;
                    state <= SHOW_COMP;
                end if;

            --------------------------------------------------------------------
            when SHOW_COMP =>
                if t_cnt = HALF_SEC-1 then
                    -- work out who wins
                    if user_choice = comp_choice then
                        result <= 0;                                -- tie
                    elsif (user_choice=0 and comp_choice=2) or
                          (user_choice=1 and comp_choice=0) or
                          (user_choice=2 and comp_choice=1) then
                        result <= 1;                                -- win
                    else
                        result <= 2;                                -- lose
                    end if;
                    t_cnt <= (others=>'0');
                    state <= SHOW_RES;
                else
                    t_cnt <= t_cnt + 1;
                end if;

            --------------------------------------------------------------------
            when SHOW_RES =>
                if t_cnt = HALF_SEC-1 then
                    state <= WAIT_INPUT;
                    t_cnt <= (others=>'0');
                else
                    t_cnt <= t_cnt + 1;
                end if;
            end case;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 7-segment display  (we only use digit 0)
    ----------------------------------------------------------------------------
    AN <= "11111110";                                -- enable digit 0 only

    with state select
        CA <= seg_pat(ch_choice(comp_choice)) when SHOW_COMP,
              seg_pat(ch_result(result))      when SHOW_RES,
              (others=>'1')                   when others;

    ----------------------------------------------------------------------------
    -- LEDs:  LED0 = win, LED1 = lose, LED2 = tie
    ----------------------------------------------------------------------------
    LED <= (others=>'0');
    LED(0) <= '1' when state=SHOW_RES and result=1 else '0'; -- win
    LED(1) <= '1' when state=SHOW_RES and result=2 else '0'; -- lose
    LED(2) <= '1' when state=SHOW_RES and result=0 else '0'; -- tie
end architecture;
