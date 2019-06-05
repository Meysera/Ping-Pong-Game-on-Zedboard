------------------------------------------------------------
-- Company:     ESTU
-- Engineer:    Meysera Genco  
-- 
-- Create Date: 12.04.2019 10:02:55
-- Design Name: 
-- Module Name: VGA_timing_controller - Behavioral
-- Project Name: PongGame
-- Target Devices: 
-- Tool Versions: 
-- Description: This component is responsable of generating
-- the 3_bit RGB signal.
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
------------------------------------------------------------
 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.numeric_std.ALL;

entity Pixel_generation_circuit is
    Port ( 
            clk, reset  :   in std_logic;
            Ball_V       : in  std_logic_vector(31 downto 0);
            L_pad_control:  in std_logic_vector(1 downto 0);
            R_pad_control:  in std_logic_vector(1 downto 0);
            video_on    :   in STD_LOGIC;
            pixel_x     :   in std_logic_vector(10 downto 0);
            pixel_y     :   in std_logic_vector(10 downto 0);
            rgb         :   out STD_LOGIC_VECTOR (11 downto 0);
            R_side_s:   out unsigned(2 downto 0);
            L_side_s:   out unsigned(2 downto 0));
end Pixel_generation_circuit;

architecture Behavioral of Pixel_generation_circuit is
-- btn connected to up/down pushbuttons for now but
-- eventually will get data from UART..

-- Signal used to control speed of ball and how
-- often pushbuttons are checked for paddle movement.
    signal refr_tick: std_logic;

-- x and y coordinates from (0,0) to (1800,1000)
    signal   pix_x: unsigned(10 downto 0);
    signal   pix_y: unsigned(10 downto 0);
-- screen dimensions
    constant MAX_X:         integer := 1600;
    constant MAX_Y:         integer := 900;
-- **********************************************
-- Left and right boundary of the wall
    constant midLine_X_L:      integer := 798;
    constant midLine_X_R:      integer := 802;
-- **********************************************

-- Left paddle's left, right, top, bottom and height.
-- left & right are constants. top & bottom are signals to allow movement.
-- L_bar_y_t driven by reg below.
    constant L_PAD_X_L:     integer := 100;
    constant L_PAD_X_R:     integer := 105;
    constant L_PAD_Y_SIZE:  integer := 75;
-- reg to track top boundary (x position is fixed)
    signal  L_PAD_Y_P:      unsigned(10 downto 0) := "00111000010";
    signal  L_PAD_Y_P_next: unsigned(10 downto 0) := "00111000010";
-- Left paddle's OFFSET FROM IT'S POSITION    
    signal  L_PAD_Y_T:      unsigned(10 downto 0);
    signal  L_PAD_Y_B:      unsigned(10 downto 0);  
      
-- Right paddle's left, right, top, bottom and height.
-- left & right are constants. top & bottom are signals to allow movement.
-- R_bar_y_t driven by reg below.
    constant R_PAD_X_L:     integer := MAX_X - L_PAD_X_L - 5;
    constant R_PAD_X_R:     integer := MAX_X - L_PAD_X_L ;
    constant R_PAD_Y_SIZE:  integer := 75;
-- reg to track top boundary (x position is fixed)
    signal R_PAD_Y_P:       unsigned(10 downto 0) := "00111000010";
    signal R_PAD_Y_P_next:  unsigned(10 downto 0) := "00111000010";
-- Right paddle's OFFSET FROM IT'S POSITION
    signal R_PAD_Y_T:       unsigned(10 downto 0);
    signal R_PAD_Y_B:       unsigned(10 downto 0);

-- bars shifting velocity when a button is pressed
    constant BAR_V: integer:= 8;

-- reg to track ball position
    constant BALL_SIZE:     integer := 100;
    signal   ball_x_p, ball_x_p_next:     unsigned(10 downto 0);
    signal   ball_y_p, ball_y_p_next:     unsigned(10 downto 0);
-- ball speed
    signal   Ball_x_vel, Ball_x_vel_next:   unsigned(10 downto 0);
    signal   Ball_y_vel, Ball_y_vel_next:   unsigned(10 downto 0);
    
-- ball movement can be pos or neg
    signal BALL_V_INTEGER: integer:= 8;
    signal BALL_V_P: unsigned(10 downto 0):= to_unsigned(BALL_V_INTEGER,11);
    signal BALL_V_N: unsigned(10 downto 0):= unsigned(to_signed(-BALL_V_INTEGER,11));

-- Object output signals
    signal Boarder_on, midLine_on, L_PAD_on, R_PAD_on, ball_on:      std_logic;
    signal Boarder_rgb, midLine_rgb, L_PAD_rgb, R_PAD_rgb, ball_rgb: std_logic_vector(11 downto 0);
    signal r_point1_rgb, r_point2_rgb, r_point3_rgb:    std_logic_vector(11 downto 0);
    signal r_point1_rgb_next, r_point2_rgb_next, r_point3_rgb_next:    std_logic_vector(11 downto 0);
    signal l_point1_rgb, l_point2_rgb, l_point3_rgb:    std_logic_vector(11 downto 0);
    signal l_point1_rgb_next, l_point2_rgb_next, l_point3_rgb_next:    std_logic_vector(11 downto 0);
    signal r_point1_on, r_point2_on, r_point3_on:   std_logic;
    signal l_point1_on, l_point2_on, l_point3_on:   std_logic;
-- Score signals
    signal R_side_score:    unsigned(2 downto 0);
    signal R_side_s_next:   unsigned(2 downto 0);
    signal L_side_score:    unsigned(2 downto 0);
    signal L_side_s_next:   unsigned(2 downto 0);
    constant score_point_r: integer := 150;
    constant score_point_y: integer := 25;
begin

Ball_V_INTEGER <= TO_INTEGER(unsigned(Ball_V));
BALL_V_P <= to_unsigned(8,11);
BALL_V_N <= unsigned(to_signed(-8,11));

R_side_s <= R_side_score;
L_side_s <= L_side_score;

pix_x <= unsigned(pixel_x);
pix_y <= unsigned(pixel_y);

process (clk, reset)
    begin
        if (reset = '1') then
            R_PAD_Y_P    <= ("00111000010");
            L_PAD_Y_P    <= ("00111000010");
            ball_x_p     <= ("01100100000");
            ball_y_p     <= ("00111000010");
            Ball_x_vel   <= ("00000001000");
            Ball_y_vel   <= ("00000001000");
            R_side_score <= ("000");
            L_side_score <= ("000");
            r_point1_rgb <= x"222";
            r_point2_rgb <= x"222";
            r_point3_rgb <= x"222";
            l_point1_rgb <= x"222";
            l_point2_rgb <= x"222";
            l_point3_rgb <= x"222";
        elsif (clk'event and clk = '1') then
            R_PAD_Y_P    <= R_PAD_Y_P_next;
            L_PAD_Y_P    <= L_PAD_Y_P_next;
            ball_x_p     <= ball_x_p_next;
            ball_y_p     <= ball_y_p_next;
            Ball_x_vel   <= Ball_x_vel_next;
            Ball_y_vel   <= Ball_y_vel_next;
            R_side_score <= R_side_s_next;
            L_side_score <= L_side_s_next;
            r_point1_rgb <= r_point1_rgb_next;
            r_point2_rgb <= r_point2_rgb_next;
            r_point3_rgb <= r_point3_rgb_next;
            l_point1_rgb <= l_point1_rgb_next;
            l_point2_rgb <= l_point2_rgb_next;
            l_point3_rgb <= l_point3_rgb_next;
            else 
            R_PAD_Y_P    <= R_PAD_Y_P;
            L_PAD_Y_P    <= L_PAD_Y_P;
            ball_x_p     <= ball_x_p;
            ball_y_p     <= ball_y_p;
            Ball_x_vel   <= Ball_x_vel;
            Ball_y_vel   <= Ball_y_vel;
            R_side_score <= R_side_score;
            L_side_score <= L_side_score;
            r_point1_rgb <= r_point1_rgb;
            r_point2_rgb <= r_point2_rgb;
            r_point3_rgb <= r_point3_rgb;
            l_point1_rgb <= l_point1_rgb;
            l_point2_rgb <= l_point2_rgb;
            l_point3_rgb <= l_point3_rgb;
        end if;
end process;

-- pixel within mid-line
midLine_on <= '1' when ((midLine_X_L <= to_integer(pix_x)) and (to_integer(pix_x) <= midLine_X_R) and (50 <= to_integer(pix_y)) and (to_integer(pix_y) <= 850))
         else '0';
midLine_rgb <= x"0f0";  -- GREEN
    
-- pixel within boarder
Boarder_on <= '1' when (((1550 <= to_integer(pix_x)) and (to_integer(pix_x) <= 1554)) or ((46 <= to_integer(pix_x)) and (to_integer(pix_x) <= 50)) or ((850 <= to_integer(pix_y)) and (to_integer(pix_y) <= 854)) or ((46 <= to_integer(pix_y)) and (to_integer(pix_y) <= 50)))
         else '0';
Boarder_rgb <= x"f00";  -- RED

-- pixel within score points
r_point1_on <= '1' when ((to_integer(pix_x) - 840)*(to_integer(pix_x) - 840) + (to_integer(pix_y) - score_point_y)*(to_integer(pix_y) - score_point_y) <= score_point_r) 
         else '0';
r_point2_on <= '1' when ((to_integer(pix_x) - 880)*(to_integer(pix_x) - 880) + (to_integer(pix_y) - score_point_y)*(to_integer(pix_y) - score_point_y) <= score_point_r) 
         else '0';
r_point3_on <= '1' when ((to_integer(pix_x) - 920)*(to_integer(pix_x) - 920) + (to_integer(pix_y) - score_point_y)*(to_integer(pix_y) - score_point_y) <= score_point_r) 
         else '0';

l_point1_on <= '1' when ((to_integer(pix_x) - 760)*(to_integer(pix_x) - 760) + (to_integer(pix_y) - score_point_y)*(to_integer(pix_y) - score_point_y) <= score_point_r) 
         else '0';
l_point2_on <= '1' when ((to_integer(pix_x) - 720)*(to_integer(pix_x) - 720) + (to_integer(pix_y) - score_point_y)*(to_integer(pix_y) - score_point_y) <= score_point_r) 
         else '0';
l_point3_on <= '1' when ((to_integer(pix_x) - 680)*(to_integer(pix_x) - 680) + (to_integer(pix_y) - score_point_y)*(to_integer(pix_y) - score_point_y) <= score_point_r) 
         else '0';
         
-- refr_tick: 1-clock tick asserted at start of v_sync,
-- e.g., when the screen is refreshed
-- speed is 60 Hz
refr_tick <= '1' when (pix_y = 901) and (pix_x = 0)   -- I use a 1600x600 display
        else '0';
       
-- pixel within R_paddle
R_PAD_Y_T   <= R_PAD_Y_P - R_PAD_Y_SIZE;
R_PAD_Y_B   <= R_PAD_Y_P + R_PAD_Y_SIZE;
R_PAD_on    <= '1' when ((R_PAD_X_L <= to_integer(pix_x)) and (to_integer(pix_x) <= R_PAD_X_R) and (R_PAD_Y_T <= to_integer(pix_y))and (to_integer(pix_y) <= R_PAD_Y_B)) 
          else '0';
R_PAD_rgb <= x"0ff"; -- Turquison
    
-- pixel within L_paddle
L_PAD_Y_T   <= L_PAD_Y_P - L_PAD_Y_SIZE;
L_PAD_Y_B   <= L_PAD_Y_P + L_PAD_Y_SIZE;
L_PAD_on    <= '1' when ((L_PAD_X_L <= to_integer(pix_x)) and (to_integer(pix_x) <= L_PAD_X_R) and (L_PAD_Y_T <= to_integer(pix_y))and (to_integer(pix_y) <= L_PAD_Y_B)) 
          else '0';
L_PAD_rgb <= x"d6f";  -- purple

-- pixel within ball
ball_on <= '1' when ((to_integer(pix_x) - to_integer(ball_x_p))*(to_integer(pix_x) - to_integer(ball_x_p)) + (to_integer(pix_y) - to_integer(ball_y_p))*(to_integer(pix_y) - to_integer(ball_y_p)) <= BALL_SIZE) 
         else '0';
    ball_rgb <= x"ff0"; -- Yellow

-- Process L_PAD movement control
process( L_PAD_Y_P, L_PAD_Y_B, L_PAD_Y_T, refr_tick, L_pad_control)
begin
L_PAD_Y_P_next <= L_PAD_Y_P; -- no movement
if ( refr_tick = '1' ) then
    -- if btn_L 1 pressed and paddle not at bottom yet
    if ( L_pad_control(0) = '1' and L_PAD_Y_B < (MAX_Y - 51 - BAR_V)) then
        L_PAD_Y_P_next <= L_PAD_Y_P + BAR_V;
    -- if btn_D 0 pressed and bar not at top yet
    elsif ( L_pad_control(1) = '1' and L_PAD_Y_T > (51 + BAR_V)) then
        L_PAD_Y_P_next <= L_PAD_Y_P - BAR_V;
    end if;
end if;
end process;

-- Process R_PAD movement control
process( R_PAD_Y_P, R_PAD_Y_B, R_PAD_Y_T, refr_tick, R_pad_control)
begin
R_PAD_Y_P_next <= R_PAD_Y_P; -- no movement
if ( refr_tick = '1' ) then
    -- if btn_R 1 pressed and paddle not at bottom yet
    if ( R_pad_control(1) = '1' and R_PAD_Y_B < (MAX_Y - 51 - BAR_V)) then
        R_PAD_Y_P_next <= R_PAD_Y_P + BAR_V;
    -- if btn_U 0 pressed and bar not at top yet
    elsif ( R_pad_control(0) = '1' and R_PAD_Y_T > (51 + BAR_V)) then
        R_PAD_Y_P_next <= R_PAD_Y_P - BAR_V;
    end if;
end if;
end process;

-- Ubdate the right side's score points
process(R_side_score)
begin
    r_point1_rgb_next <= r_point1_rgb;
    r_point2_rgb_next <= r_point2_rgb;
    r_point3_rgb_next <= r_point3_rgb;
    if (R_side_score = "001") then
        r_point1_rgb_next <= x"0ff";
        r_point2_rgb_next <= x"222";
        r_point3_rgb_next <= x"222";
    elsif (R_side_score = "010") then
        r_point1_rgb_next <= x"0ff";
        r_point2_rgb_next <= x"0ff";
        r_point3_rgb_next <= x"222";
    elsif (R_side_score = "011") then
        r_point1_rgb_next <= x"0ff";
        r_point2_rgb_next <= x"0ff";
        r_point3_rgb_next <= x"0ff";
    else
        r_point1_rgb_next <= x"222";
        r_point2_rgb_next <= x"222";
        r_point3_rgb_next <= x"222";
    end if;
end process;

-- Ubdate the left side score points
process(L_side_score)
begin
    l_point1_rgb_next <= l_point1_rgb;
    l_point2_rgb_next <= l_point2_rgb;
    l_point3_rgb_next <= l_point3_rgb;
    if (l_side_score = "001") then
        l_point1_rgb_next <= x"d6f";
        l_point2_rgb_next <= x"222";
        l_point3_rgb_next <= x"222";
    elsif (l_side_score = "010") then
        l_point1_rgb_next <= x"d6f";
        l_point2_rgb_next <= x"d6f";
        l_point3_rgb_next <= x"222";
    elsif (l_side_score = "011") then
        l_point1_rgb_next <= x"d6f";
        l_point2_rgb_next <= x"d6f";
        l_point3_rgb_next <= x"d6f";
    else
        l_point1_rgb_next <= x"222";
        l_point2_rgb_next <= x"222";
        l_point3_rgb_next <= x"222";
        
    end if;
end process;

-- Update the ball position 60 times per second.
ball_x_p_next <= ball_x_p + ball_x_vel when refr_tick = '1'
            else "01100100000" when ((1549 <= to_integer(ball_x_p)) or (to_integer(ball_x_p) <= 51))
            else ball_x_p;
ball_y_p_next <= ball_y_p + ball_y_vel when refr_tick = '1'
            else "00111000010" when ((1549 <= to_integer(ball_x_p)) or (to_integer(ball_x_p) <= 51))
            else ball_y_p;

process (ball_x_p,L_side_score)
begin 
    R_side_s_next <= R_side_score;
    L_side_s_next <= L_side_score;
    if (to_integer(ball_x_p) <= 51)then
        R_side_s_next <= R_side_score + 1;
    elsif (1549 <= to_integer(ball_x_p)) then
        L_side_s_next <= L_side_score + 1;
    elsif (R_side_score = 4 or L_side_score = 4) then
        R_side_s_next <= ("000");
        L_side_s_next <= ("000");
    end if;
end process;

-- Set the value of the next ball position according to
-- the boundaries.
process(ball_x_vel, ball_y_vel, ball_x_p, ball_y_p, R_PAD_Y_T, R_PAD_Y_B, L_PAD_Y_T, L_PAD_Y_B)
begin
ball_x_vel_next <= ball_x_vel;
ball_y_vel_next <= ball_y_vel;
-- ball reached top, make offset positive
if ( ball_y_p < 51 ) then   -- ball's radius is 10 "squareRoot(ball_size)"
ball_y_vel_next <= BALL_V_P;
-- reached bottom, make negative
elsif (ball_y_p > (MAX_Y - 51)) then
ball_y_vel_next <= BALL_V_N;

-- X position of ball inside L_paddle
elsif (((L_PAD_X_L - 20) <= to_integer(ball_x_p)) and (to_integer(ball_x_p) <= L_PAD_X_R)) then
    -- y portion of ball hitting L_paddle. so, reverse direction
    if ((L_PAD_Y_T <= ball_y_p) and (ball_y_p <= L_PAD_Y_B)) then
        ball_x_vel_next <= BALL_V_P;
    end if;
-- X position of ball inside R_paddle
elsif ((R_PAD_X_L <= to_integer(ball_x_p)) and (to_integer(ball_x_p) <= (R_PAD_X_R+20))) then
    -- y portion of ball hitting R_paddle. so, reverse direction
    if ((R_PAD_Y_T <= ball_y_p) and (ball_y_p <= R_PAD_Y_B)) then
        ball_x_vel_next <= BALL_V_N;
    end if;
end if;
end process;

process (video_on, R_PAD_on, R_PAD_rgb, L_PAD_on, L_PAD_rgb, ball_on, ball_rgb,
        midLine_on, midLine_rgb, Boarder_on, Boarder_rgb, r_point1_on, r_point1_rgb, 
        r_point2_on, r_point2_rgb, r_point3_on, r_point3_rgb, l_point1_on, l_point1_rgb, 
        l_point2_on, l_point2_rgb, l_point3_on, l_point3_rgb)
begin
    if (video_on = '0') then
        rgb <= x"000"; -- Blank
    else -- Priority encoding implict here
        if (L_PAD_on = '1') then
            rgb <= L_PAD_rgb;
        elsif (R_PAD_on = '1') then
            rgb <= R_PAD_rgb;
        elsif (ball_on = '1') then
            rgb <= ball_rgb;
        elsif (midLine_on = '1') then
            rgb <= midLine_rgb;
        elsif (Boarder_on = '1') then
            rgb <= Boarder_rgb;   
        elsif (r_point1_on = '1') then 
            rgb <= r_point1_rgb;
        elsif (r_point2_on = '1') then 
            rgb <= r_point2_rgb;
        elsif (r_point3_on = '1') then 
            rgb <= r_point3_rgb;
        elsif (l_point1_on = '1') then 
            rgb <= l_point1_rgb;
        elsif ( l_point2_on = '1') then 
            rgb <=  l_point2_rgb;
        elsif ( l_point3_on = '1') then 
            rgb <=  l_point3_rgb;                 
        else
            rgb <= x"000"; -- Black background
        end if;
    end if;
end process;
                    
end Behavioral;
