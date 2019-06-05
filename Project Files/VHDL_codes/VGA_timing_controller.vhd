----------------------------------------------------------------------------------
-- Company:     ESTU
-- Engineer:    Meysera Genco  
-- 
-- Create Date: 10.04.2019 10:02:55
-- Design Name: 
-- Module Name: VGA_timing_controller - Behavioral
-- Project Name: PongGame
-- Target Devices: 
-- Tool Versions: 
-- Description: A code used to generate the horizontal and vertical pulses 
--              and a signal which indicates when the timing is in the Active Video part.
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
entity VGA_timing_controller is
    Port ( 
        clk_108MHz_inp      : in STD_LOGIC;
        rst_inp             : in STD_LOGIC;
        pixel_x             : out std_logic_vector(10 downto 0);
        pixel_y             : out std_logic_vector(10 downto 0);
        hsync_outp          : out STD_LOGIC;
        vsync_outp          : out STD_LOGIC;
        video_active_outp   : out STD_LOGIC);
end VGA_timing_controller;

architecture Behavioral of VGA_timing_controller is

-- Parameters
constant H_DISPLAY_cste     : INTEGER := 1600;   -- Nb Active Pixels Per Line    1680
constant H_FP_cste          : INTEGER := 24;     -- Nb clocks front proch        104
constant H_PULSE_cste       : INTEGER := 80;     -- Nb clocks horizontal sync    184
constant H_BP_cste          : INTEGER := 96;     -- Nb clocks back proch         288

constant V_DISPLAY_cste     : INTEGER := 900;    -- Nb Active Line Per Frame     1050
constant V_FP_cste          : INTEGER := 1;      -- Nb Lines front proch         1
constant V_PULSE_cste       : INTEGER := 3;      -- Nb Lines horizontal sync     3
constant V_BP_cste          : INTEGER := 96;     -- Nb Lines back proch          33

-- Computations
constant H_START_PULSE_cste : INTEGER := H_DISPLAY_cste + H_FP_cste;
constant H_END_PULSE_cste   : INTEGER := H_START_PULSE_cste + H_PULSE_cste;
constant V_START_PULSE_cste : INTEGER := V_DISPLAY_cste + V_FP_cste;
constant V_END_PULSE_cste   : INTEGER := V_START_PULSE_cste + V_PULSE_cste;
constant H_PERIOD_cste      : INTEGER := H_DISPLAY_cste + H_FP_cste + H_PULSE_cste + H_BP_cste;  -- number of pixel clocks per line
constant V_PERIOD_cste      : INTEGER := V_DISPLAY_cste + V_FP_cste + V_PULSE_cste + V_BP_cste;  -- number of lines per frame

--signal clk                  : STD_LOGIC;
signal reset                : STD_LOGIC;
signal counter_pixel_sig    : INTEGER RANGE 0 TO H_PERIOD_cste - 1 := 0;
signal counter_line_sig     : INTEGER RANGE 0 TO V_PERIOD_cste - 1 := 0;


begin

main_proc : process(clk_108MHz_inp)
begin
    if(rising_edge(clk_108MHz_inp))then
        if(rst_inp = '1') then
            hsync_outp          <= '0';
            vsync_outp          <= '0';
            video_active_outp   <= '0';
        else
            -- Start HSYNC Pulse
            if(counter_pixel_sig = H_START_PULSE_cste-1) then
                hsync_outp <= '0';
            -- End HSYNC Pulse
            elsif(counter_pixel_sig = H_END_PULSE_cste-1) then
                hsync_outp <= '1';
            end if;
            
            -- Start VSYNC Pulse
            if(counter_pixel_sig = H_PERIOD_cste-1) and (counter_line_sig = V_START_PULSE_cste-1) then
                VSYNC_outp <= '1';
            -- End VSYNC Pulse
            elsif(counter_pixel_sig = H_PERIOD_cste-1) and (counter_line_sig = V_END_PULSE_cste-1) then
                VSYNC_outp  <= '0';
            end if;
            
            -- Active video
            if((counter_line_sig < V_DISPLAY_cste) and (counter_pixel_sig < H_DISPLAY_cste)) then
                video_active_outp   <= '1';
            -- Blank periods
            else
                video_active_outp   <= '0';
            end if;
        end if;
    end if;
end process;

counter_proc : process(clk_108MHz_inp)
begin
    if(rising_edge(clk_108MHz_inp)) then
        if(rst_inp = '1') then
            counter_pixel_sig   <= 0;
        else
            if(counter_pixel_sig = H_PERIOD_cste-1) then
                counter_pixel_sig   <= 0;
                
                if(counter_line_sig = V_PERIOD_cste-1)then
                    counter_line_sig   <= 0;
                else
                    counter_line_sig   <= counter_line_sig + 1;
                end if;
                
            else
                counter_pixel_sig   <= counter_pixel_sig + 1;
            end if;
        end if;
    end if;
end process;
pixel_x <=  std_logic_vector(to_unsigned(counter_pixel_sig,pixel_x'length));
pixel_y <= std_logic_vector(to_unsigned(counter_line_sig,pixel_y'length));

end Behavioral;
