library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use WORK.display_helpers.all;    -- for seg_pat, rpc_ch_choice, rpc_ch_result

entity rock_paper_scissors is
    port (
        clk       : in  std_logic;           -- 100 MHz
        btn_l     : in  std_logic;           -- ROCK     (BTNL)
        btn_u     : in  std_logic;           -- PAPER    (BTNU)
        btn_r     : in  std_logic;           -- SCISSORS (BTNR)
        AN        : out std_logic_vector(7 downto 0);
        CA        : out std_logic_vector(6 downto 0);
        LED       : out std_logic_vector(15 downto 0)
    );
end entity;

architecture Behavioral of rock_paper_scissors is

    -- FSM states
    type state_t is (WAIT_INPUT, SHOW_COMP, SHOW_RES);
    signal state       : state_t := WAIT_INPUT;

    -- choices & result: 0=R,1=P,2=S; result: 0=tie,1=win,2=loss
    signal user_choice : integer range 0 to 2 := 0;
    signal comp_choice : integer range 0 to 2 := 0;
    signal result      : integer range 0 to 2 := 0;

    -- LFSR for pseudo-random
    signal lfsr : std_logic_vector(16 downto 0) := "11010101100111010";
    signal fb   : std_logic;

    -- button synchronizers
    signal sync_l, sync_u, sync_r : std_logic_vector(1 downto 0) := (others=>'0');
    signal hit_l, hit_u, hit_r    : std_logic;

    -- timing for SHOW phases
    constant SHOW_COMP_TIME : unsigned(25 downto 0) := to_unsigned(350_000_000, 26);  -- 3.5 s
    constant SHOW_RES_TIME  : unsigned(25 downto 0) := to_unsigned(400_000_000, 26);  -- 4 s
    signal   t_cnt          : unsigned(25 downto 0) := (others=>'0');

    -- record of wins, losses, ties
    signal wins   : integer range 0 to 9 := 0;
    signal losses : integer range 0 to 9 := 0;
    signal ties   : integer range 0 to 9 := 0;

    -- dash pattern (segments ABCDEF=off, G=on)
    constant DASH_PAT : std_logic_vector(6 downto 0) := "1111110";

    -- 8-digit multiplexing
    constant REFRESH_MAX : unsigned(15 downto 0) := to_unsigned(20_000, 16);
    signal  refresh_cnt  : unsigned(15 downto 0) := (others=>'0');
    signal  scan_digit   : integer range 0 to 7 := 0;

begin

    ----------------------------------------------------------------------------
    -- LFSR process
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            fb   <= lfsr(16) xor lfsr(13);
            lfsr <= lfsr(15 downto 0) & fb;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Button-press edge detection
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
    -- Main FSM: WAIT_INPUT → SHOW_COMP → SHOW_RES
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            case state is

                when WAIT_INPUT =>
                    t_cnt <= (others=>'0');
                    if hit_l='1' or hit_u='1' or hit_r='1' then
                        if    hit_l='1' then user_choice <= 0;  -- Rock
                        elsif hit_u='1' then user_choice <= 1;  -- Paper
                        else                 user_choice <= 2;  -- Scissors
                        end if;
                        comp_choice <= to_integer(unsigned(lfsr(1 downto 0))) mod 3;
                        state       <= SHOW_COMP;
                    end if;

                when SHOW_COMP =>
                    if t_cnt = SHOW_COMP_TIME then
                        -- determine result & update record
                        if user_choice = comp_choice then
                            result <= 0;  ties   <= ties   + 1;
                        elsif (user_choice=0 and comp_choice=2) or
                              (user_choice=1 and comp_choice=0) or
                              (user_choice=2 and comp_choice=1) then
                            result <= 1;  wins   <= wins   + 1;
                        else
                            result <= 2;  losses <= losses + 1;
                        end if;
                        t_cnt <= (others=>'0');
                        state <= SHOW_RES;
                    else
                        t_cnt <= t_cnt + 1;
                    end if;

                when SHOW_RES =>
                    if t_cnt = SHOW_RES_TIME then
                        state <= WAIT_INPUT;
                        t_cnt  <= (others=>'0');
                    else
                        t_cnt <= t_cnt + 1;
                    end if;

            end case;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 8-Digit 7-Segment Multiplex Scanner
    -- [7]=wins, [6]=losses, [5]=ties, [4]=dash, [3]=dash,
    -- [2]=result, [1]=comp, [0]=user
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            -- refresh counter
            if refresh_cnt = REFRESH_MAX then
                refresh_cnt <= (others=>'0');
                if scan_digit = 7 then
                    scan_digit <= 0;
                else
                    scan_digit <= scan_digit + 1;
                end if;
            else
                refresh_cnt <= refresh_cnt + 1;
            end if;

            -- drive AN/CA for each digit
            case scan_digit is
                when 0 =>
                    AN <= "11111110";
                    CA <= seg_pat(rpc_ch_choice(user_choice));

                when 1 =>
                    AN <= "11111101";
                    if state /= WAIT_INPUT then
                        CA <= seg_pat(rpc_ch_choice(comp_choice));
                    else
                        CA <= (others=>'1');
                    end if;

                when 2 =>
                    AN <= "11111011";
                    if state = SHOW_RES then
                        CA <= seg_pat(rpc_ch_result(result));
                    else
                        CA <= (others=>'1');
                    end if;

                when 3 =>
                    AN <= "11110111";
                    CA <= DASH_PAT;

                when 4 =>
                    AN <= "11101111";
                    CA <= DASH_PAT;

                when 5 =>
                    AN <= "11011111";
                    CA <= seg_pat(character'val(character'pos('0') + ties));

                when 6 =>
                    AN <= "10111111";
                    CA <= seg_pat(character'val(character'pos('0') + losses));

                when 7 =>
                    AN <= "01111111";
                    CA <= seg_pat(character'val(character'pos('0') + wins));

                when others =>
                    AN <= (others=>'1');
                    CA <= (others=>'1');
            end case;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- LEDs: 0=win,1=loss,2=tie when showing result
    ----------------------------------------------------------------------------
    LED <= (others=>'0');
    LED(0) <= '1' when state=SHOW_RES and result=1 else '0';
    LED(1) <= '1' when state=SHOW_RES and result=2 else '0';
    LED(2) <= '1' when state=SHOW_RES and result=0 else '0';

end architecture Behavioral;
