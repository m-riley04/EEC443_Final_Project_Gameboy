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

architecture Behavioral of rock_paper_scissors is
    type state_t is (WAIT_INPUT, SHOW_COMP, SHOW_RES);
    signal state        : state_t := WAIT_INPUT;

    signal user_choice  : integer range 0 to 2 := 0;  -- 0 = R, 1 = P, 2 = S
    signal comp_choice  : integer range 0 to 2 := 0;
    signal result       : integer range 0 to 2 := 0;  -- 0 = tie, 1 = win, 2 = lose

    -- LFSR
    signal lfsr : std_logic_vector(16 downto 0) := "11010101100111010";
    signal fb   : std_logic;

    -- Sync for buttons
    signal sync_l, sync_u, sync_r : std_logic_vector(1 downto 0) := (others=>'0');
    signal hit_l,  hit_u,  hit_r  : std_logic;

    -- Timer for display delays
    constant HALF_SEC : unsigned(25 downto 0) := to_unsigned(50_000_000, 26);
    signal   t_cnt    : unsigned(25 downto 0) := (others=>'0');
    
     -- for 100 MHz → ~5 kHz digit-scan (≈1.6 kHz per digit)
     constant REFRESH_MAX : unsigned(15 downto 0) := to_unsigned(20_000, 16);
     signal refresh_cnt : unsigned(15 downto 0) := (others => '0');
     signal scan_digit  : integer range 0 to 2 := 0;
    
begin
    -- LFSR update clock
    process(clk)
    begin
        if rising_edge(clk) then
            fb   <= lfsr(16) xor lfsr(13);          -- taps 17 & 14
            lfsr <= lfsr(15 downto 0) & fb;
        end if;
    end process;

    -- Button press detection
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

    -- FSM
    process(clk)
    begin
        if rising_edge(clk) then
            case state is
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

    -- multiplex three 7-segment digits:
--   digit 0 = user choice
--   digit 1 = comp choice (only once user has picked)
--   digit 2 = result      (only during SHOW_RES)
process(clk)
begin
  if rising_edge(clk) then
    -- refresh timing
    if refresh_cnt = REFRESH_MAX then
      refresh_cnt <= (others => '0');
      if scan_digit = 2 then
        scan_digit <= 0;
      else
        scan_digit <= scan_digit + 1;
      end if;
    else
      refresh_cnt <= refresh_cnt + 1;
    end if;

    -- drive AN/CA for the current scan_digit
    case scan_digit is
      when 0 =>
        AN <= "11111110";  -- digit 0 on
        CA <= seg_pat(rpc_ch_choice(user_choice));
      when 1 =>
        AN <= "11111101";  -- digit 1 on
        if state /= WAIT_INPUT then
          CA <= seg_pat(rpc_ch_choice(comp_choice));
        else
          CA <= (others=>'1');  -- blank if no choice yet
        end if;
      when 2 =>
        AN <= "11111011";  -- digit 2 on
        if state = SHOW_RES then
          CA <= seg_pat(rpc_ch_result(result));
        else
          CA <= (others=>'1');  -- blank until result
        end if;
    end case;
  end if;
end process;

    -- LED displays
    LED <= (others=>'0');
    LED(0) <= '1' when state=SHOW_RES and result=1 else '0'; -- win
    LED(1) <= '1' when state=SHOW_RES and result=2 else '0'; -- lose
    LED(2) <= '1' when state=SHOW_RES and result=0 else '0'; -- tie
end architecture;
