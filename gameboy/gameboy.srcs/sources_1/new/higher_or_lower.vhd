library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use WORK.display_helpers.all;               -- segment patterns

entity higher_or_lower is
    port (
        clk       : in  std_logic;          -- 100 MHz
        guess     : in  std_logic_vector(14 downto 0);
        btn_c     : in  std_logic;
        AN        : out std_logic_vector(7 downto 0);
        CA        : out std_logic_vector(6 downto 0);
        LED       : out std_logic_vector(15 downto 0)
    );
end entity;

architecture Behavioral of higher_or_lower is
    type state_t is (WAIT_INPUT, SHOW_COMP, SHOW_RES);
    signal state        : state_t := WAIT_INPUT;

    signal user_choice  : integer range 0 to 32768 := 0;  -- 0 = R, 1 = P, 2 = S
    signal comp_choice  : integer range 0 to 32768 := 0;
    signal result       : integer range 0 to 2 := 0;  -- 0 = lower, 1 = win, 2 = higher

    -- LFSR
    signal lfsr : std_logic_vector(16 downto 0) := "11010101100111010";
    signal fb   : std_logic;

    -- Sync for buttons
    signal sync_c : std_logic_vector(1 downto 0) := (others=>'0');
    signal hit_c : std_logic;

    -- Timer for display delays
    constant HALF_SEC : unsigned(25 downto 0) := to_unsigned(50_000_000, 26); 
    signal   t_cnt    : unsigned(25 downto 0) := (others=>'0');

    
begin
    -- LFSR update clock
    process(clk)
    begin
        if rising_edge(clk) then
            fb   <= lfsr(16) xor lfsr(13);-- taps 17 & 14
            lfsr <= lfsr(15 downto 0) & fb;
        end if;
    end process;

    -- Button press detection
    process(clk)
    begin
        if rising_edge(clk) then
            sync_c <= sync_c(0) & btn_c;
            hit_c  <= sync_c(0) and not sync_c(1);
        end if;
    end process;

    -- FSM
    process(clk)
    begin
        if rising_edge(clk) then
            case state is
            when WAIT_INPUT =>
                t_cnt <= (others=>'0');
                if hit_c='1' then
                    user_choice <= to_integer(unsigned(guess(14 downto 0)));
                    comp_choice <= to_integer(unsigned(lfsr(16 downto 2)));
                    state <= SHOW_COMP;
                end if;

            when SHOW_COMP =>
                if t_cnt = HALF_SEC-1 then
                    -- work out who wins
                    if user_choice = comp_choice then
                        result <= 1;                                -- win
                    elsif comp_choice > user_choice then
                        result <= 2;                                -- higher
                    else
                        result <= 0;                                -- lower
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

    -- 7-seg display
    AN <= "11111110"; -- enable digit 0 only

    with state select
        CA <= seg_pat(hl_ch_result(result))   when SHOW_RES,
              (others=>'1')                   when others;

    -- LED displays
    LED <= (others=>'0');
    LED(0) <= '1' when state=SHOW_RES and result=1 else '0'; -- win
    LED(1) <= '1' when state=SHOW_RES and result=2 else '0'; -- lose
    LED(2) <= '1' when state=SHOW_RES and result=0 else '0'; -- tie
end architecture;
