----------------------------------------------------------------------------------
-- Company:     ESTU
-- Engineer:    Meysera Genco  
-- 
-- Create Date: 10.04.2019 10:06:20
-- Design Name: 
-- Module Name: TOP_LEVEL - Behavioral
-- Project Name: PongGame
-- Target Devices: 
-- Tool Versions: 
-- Description: Outputs values for the signals R, G and B when the video is active.
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
use IEEE.numeric_std.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TOP_LEVEL is
    Port ( clk_inp      : in STD_LOGIC;
           reset_inp    : in STD_LOGIC;
           clk_VGA      : in STD_LOGIC;
           Ball_V       : in  std_logic_vector(31 downto 0);
           Left_pad_control : in std_logic_vector(1 downto 0);
           Right_pad_control: in std_logic_vector(1 downto 0);
           
           VSYNC_outp   : out STD_LOGIC;
           HSYNC_outp   : out STD_LOGIC;
           data_R_outp  : out STD_LOGIC_VECTOR (3 downto 0);
           data_G_outp  : out STD_LOGIC_VECTOR (3 downto 0);
           data_B_outp  : out STD_LOGIC_VECTOR (3 downto 0);
           R_side_s     : out unsigned(2 downto 0);
           L_side_s     : out unsigned(2 downto 0));
end TOP_LEVEL;

architecture Behavioral of TOP_LEVEL is

component VGA_timing_controller is
    Port ( 
        clk_108MHz_inp      : in  STD_LOGIC;
        rst_inp             : in  STD_LOGIC;
        pixel_x             : out std_logic_vector(10 downto 0);
        pixel_y             : out std_logic_vector(10 downto 0);
        hsync_outp          : out STD_LOGIC;
        vsync_outp          : out STD_LOGIC;
        video_active_outp   : out STD_LOGIC);
end component VGA_timing_controller;

component Pixel_generation_circuit is
    Port ( clk, reset  :  in std_logic;
           Ball_V       : in  std_logic_vector(31 downto 0);
           L_pad_control: in std_logic_vector(1 downto 0);
           R_pad_control: in std_logic_vector(1 downto 0);
           video_on    :  in STD_LOGIC;
           pixel_x     :  in std_logic_vector(10 downto 0);
           pixel_y     :  in std_logic_vector(10 downto 0);
           rgb         :  out STD_LOGIC_VECTOR (11 downto 0);
           R_side_s     : out unsigned(2 downto 0);
           L_side_s     : out unsigned(2 downto 0));
end component Pixel_generation_circuit;

signal video_active : std_logic;
signal pixel_x      : std_logic_vector(10 downto 0);
signal pixel_y      : std_logic_vector(10 downto 0);
signal rgb          : STD_LOGIC_VECTOR (11 downto 0);
signal hsync_outp1  : STD_LOGIC;
signal vsync_outp1  : STD_LOGIC;
begin

VGA_timing_controller_0 : VGA_timing_controller
port map (
    clk_108MHz_inp      => clk_VGA,
    rst_inp             => reset_inp,
    pixel_x             => pixel_x,
    pixel_y             => pixel_y,
    hsync_outp          => hsync_outp1,
    vsync_outp          => vsync_outp1,
    video_active_outp   => video_active
);
HSYNC_outp <= hsync_outp1;
VSYNC_outp <= vsync_outp1;
Pixel_generation_circuit_0 : Pixel_generation_circuit
port map (
    clk        =>   clk_VGA,
    reset      =>   reset_inp,
    Ball_V     =>   Ball_V,
    L_pad_control => Left_pad_control,
    R_pad_control => Right_pad_control,
    video_on   =>   video_active,
    pixel_x    =>   pixel_x,
    pixel_y    =>   pixel_y,
    rgb        =>   rgb,
    R_side_s   =>   R_side_s,
    L_side_s   =>   L_side_s
);

data_R_outp <= rgb(11 downto 8);
data_G_outp <= rgb(7 downto 4);
data_B_outp <= rgb(3 downto 0);

end Behavioral;
