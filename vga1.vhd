library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
entity maze is
    Port ( clk : in  STD_LOGIC;
           btnU, btnD, btnL, btnR, btnC: in std_logic;
           led : out  STD_LOGIC_VECTOR (15 downto 0);
           seg : out  STD_LOGIC_VECTOR (6 downto 0);
           dp : out STD_LOGIC;
           an : out  STD_LOGIC_VECTOR (3 downto 0);
           sw : in  STD_LOGIC_VECTOR (15 downto 0);
           -- VGA ports
           vgaRed : out  STD_LOGIC_VECTOR(3 DOWNTO 0);
           vgaGreen : out  STD_LOGIC_VECTOR(3 DOWNTO 0);
           vgaBlue : out  STD_LOGIC_VECTOR(3 DOWNTO 0);
           HSync : out  STD_LOGIC;
           VSync : out  STD_LOGIC);
end maze;

architecture behavioral of maze is
component vga_sync 
    Port ( 
           clk : in  STD_LOGIC;
           rst: in STD_LOGIC;
           -- to VGA ports
           HSync : out  STD_LOGIC;
           VSync : out  STD_LOGIC;
           -- to Graphics Engine
           current_x: out STD_LOGIC_VECTOR(9 downto 0);
           current_y: out STD_LOGIC_VECTOR(9 downto 0);
           onDisplay: out STD_LOGIC;
           endOfFrame: out STD_LOGIC;
           clk_vga: out STD_LOGIC
           );
end component;

signal rst: STD_LOGIC;
signal colorOut: STD_LOGIC_VECTOR(11 downto 0); -- One signal to concatanate the
                   -- RGB. R is the MS nibble.
-- Sync related
signal clk_vga: STD_LOGIC;
signal current_x: STD_LOGIC_VECTOR(9 downto 0);
signal current_y: STD_LOGIC_VECTOR(9 downto 0);
signal onDisplay: STD_LOGIC;
signal endOfFrame: STD_LOGIC;
signal counterSec: std_logic_vector(26 downto 0);

-- Players
signal bottom_player_y1: STD_LOGIC_VECTOR(9 downto 0);
signal bottom_player_y2: STD_LOGIC_VECTOR(9 downto 0);
signal bottom_player_x1: STD_LOGIC_VECTOR(9 downto 0);
signal bottom_player_x2: STD_LOGIC_VECTOR(9 downto 0);
signal win: STD_LOGIC;
signal score: STD_LOGIC_VECTOR(15 downto 0);
signal hallway: std_logic_vector(4 downto 0);
signal trial: std_logic_vector(11 downto 0);
signal top_time: std_logic_vector(11 downto 0);
signal over: std_logic;
signal level: std_logic;
signal timer: STD_LOGIC_VECTOR(31 downto 0);


-- constants
constant top_border: STD_LOGIC_VECTOR(9 downto 0):=std_logic_vector(to_unsigned(53, current_y'length));
constant bottom_border: STD_LOGIC_VECTOR(9 downto 0):= std_logic_vector(to_unsigned(427, current_y'length));
constant left_border: STD_LOGIC_VECTOR(9 downto 0):=std_logic_vector(to_unsigned(123, current_x'length));
constant right_border: STD_LOGIC_VECTOR(9 downto 0):= std_logic_vector(to_unsigned(527, current_x'length));
constant border_thickness: STD_LOGIC_VECTOR(9 downto 0):= "0000000101";
constant timer_trial: STD_LOGIC_VECTOR(11 downto 0):= x"213";

-- color constants
constant RED: STD_LOGIC_VECTOR(11 downto 0) := "111100000000";
constant GREEN: STD_LOGIC_VECTOR(11 downto 0) := "000011110000";
constant BLUE: STD_LOGIC_VECTOR(11 downto 0) := "000000001111";
constant BLACK: STD_LOGIC_VECTOR(11 downto 0) := "000000000000";
constant WHITE: STD_LOGIC_VECTOR(11 downto 0) := "111111111111";

 
begin
SYNC: vga_sync port map(
        clk => clk,
        rst => rst,
        -- to VGA ports
        HSync => HSync,
        VSync => VSync,
        -- to Graphics Engine
        current_x => current_x,
        current_y => current_y,
        onDisplay => onDisplay,
    endOfFrame => endOfFrame,
        clk_vga   => clk_vga
);

vgaRed <= colorOut(11 downto 8);
vgaGreen <= colorOut(7 downto 4);
vgaBlue <= colorOut(3 downto 0);

-- GPIO init
seg <= (others => '0');
dp <= '0';
an(3 downto 0) <= (others => '1'); 
led <= score ;
rst <= sw(15);

DISPLAY:process(current_x, current_y, onDisplay, bottom_player_x1, bottom_player_x2,
  bottom_player_y1, bottom_player_y2)
   begin
    --Backdrop
    if(onDisplay = '1') then
    
     --Background not in the game
     if(current_y <= top_border - border_thickness or current_y >= bottom_border + border_thickness or
        current_x <= left_border - border_thickness or current_x >= right_border + border_thickness) then
      colorOut <= BLACK;
     
    elsif(current_y > x"30" and current_y <= x"35" and current_x >= x"7b" and current_x <= top_time) then
          colorOut<= GREEN;
          
    elsif(current_y > x"1AB" and current_y <= x"1BF" and current_x >= x"7b" and current_x <= trial) then
            colorOut<= GREEN;      
            
     -- Borders  
     elsif(
        (current_y < top_border and current_y > top_border - border_thickness) or
        (current_y > bottom_border and current_y < bottom_border + border_thickness) or
          (current_x < left_border and current_x > left_border - border_thickness) or 
      (current_x > right_border and current_x < right_border + border_thickness)
         ) then
       colorOut <= RED;
       
       -- Player is RED 
       elsif(current_y >= bottom_player_y1 and current_y < bottom_player_y2 and current_x >= bottom_player_x1 and current_x < bottom_player_x2
         ) then
       colorOut <= RED;
              
        --GAME BACKGROUND WITH PLAYER
        else
            colorOut <= BLUE;
        end if; 
     
     if(level='0') then
        if(current_y > x"3F" and current_y <= x"8F" and current_x >= x"7E" and current_x <= x"81") then --vertical 7f/3f
            colorOut <= GREEN;
        end if;
        
        if(current_y > x"3F" and current_y <= x"42" and current_x >= x"7E" and current_x <= x"FB") then --horizontal 7f/3f 
            colorOut <= GREEN;
        end if;        
        
        if(current_y > x"3F" and current_y <= x"A3" and current_x >= x"FB" and current_x <= x"FF") then --vertical fb/3f
            colorOut <= GREEN;
        end if;        

        if(current_y > x"3F" and current_y <= x"111" and current_x >= x"1F1" and current_x <= x"1F4") then --vertical 1f1,3f
            colorOut <= GREEN;
        end if;

        if(current_y > x"3F" and current_y <= x"42" and current_x >= x"1F1" and current_x <= x"205") then --horizontal 1f1,3f
            colorOut <= GREEN;
        end if;

        if(current_y > x"3F" and current_y <= x"1A5" and current_x >= x"205" and current_x <= x"208") then --vertical 205,3f
            colorOut <= GREEN;
        end if;

        if(current_y > x"53" and current_y <= x"8F" and current_x >= x"92" and current_x <= x"95") then --vertical 92,53
            colorOut <= GREEN;
        end if;
        
        if(current_y > x"53" and current_y <= x"56" and current_x >= x"92" and current_x <= x"E7") then --horizontal 92,53
            colorOut <= GREEN;
        end if;

        if(current_y > x"53" and current_y <= x"B7" and current_x >= x"E7" and current_x <= x"EA") then --vertical e7,53
            colorOut <= GREEN;
        end if;

        if(current_y > x"67" and current_y <= x"A3" and current_x >= x"141" and current_x <= x"144") then --vertical 141,67
            colorOut <= GREEN;
        end if;

        if(current_y > x"67" and current_y <= x"6A" and current_x >= x"141" and current_x <= x"1A4") then --horizontal 141,67
            colorOut <= GREEN;
        end if;

        if(current_y > x"67" and current_y <= x"F8" and current_x >= x"1A4" and current_x <= x"1A7") then --vertical 1A4,67
            colorOut <= GREEN;
        end if;

        if(current_y > x"7B" and current_y <= x"B7" and current_x >= x"15F" and current_x <= x"162") then --vertical 15f,97
             colorOut <= GREEN;
        end if;

        if(current_y > x"7B" and current_y <= x"7E" and current_x >= x"15F" and current_x <= x"190") then --horizontal 15F,97
             colorOut <= GREEN;
        end if;        

        if(current_y > x"7B" and current_y <= x"DF" and current_x >= x"190" and current_x <= x"193") then --vertical 190,7b
            colorOut <= GREEN;
        end if;

        if(current_y > x"7B" and current_y <= x"7E" and current_x >= x"15F" and current_x <= x"190") then --horizontal 15F,97
             colorOut <= GREEN;
        end if;

        if(current_y > x"8F" and current_y <= x"92" and current_x >= x"7E" and current_x <= x"92") then --horizontal 15F,97
             colorOut <= GREEN;
        end if;

        if(current_y > x"A3" and current_y <= x"A6" and current_x >= x"FB" and current_x <= x"141") then --horizontal A3,fb
             colorOut <= GREEN;
        end if;

        if(current_y > x"B7" and current_y <= x"BA" and current_x >= x"E7" and current_x <= x"15F") then --horizontal e7,b7
             colorOut <= GREEN;
        end if;

        if(current_y > x"DF" and current_y <= x"111" and current_x >= x"E7" and current_x <= x"EA") then --vertical e7,df
            colorOut <= GREEN;
        end if;

        if(current_y > x"DF" and current_y <= x"E2" and current_x >= x"E7" and current_x <= x"190") then --vertical e7,df
            colorOut <= GREEN;
        end if;

        if(current_y > x"F8" and current_y <= x"FB" and current_x >= x"FB" and current_x <= x"1A4") then --horizontal e7,df
            colorOut <= GREEN;
        end if;

        if(current_y > x"F8" and current_y <= x"111" and current_x >= x"FB" and current_x <= x"FE") then --vertical fb,f8
            colorOut <= GREEN;
        end if;

        if(current_y > x"143" and current_y <= x"161" and current_x >= x"A6" and current_x <= x"A9") then --
            colorOut <= GREEN;
        end if;

        if(current_y > x"111" and current_y <= x"114" and current_x >= x"7E" and current_x <= x"E7") then --
            colorOut <= GREEN;
        end if;

        if(current_y > x"111" and current_y <= x"161" and current_x >= x"7E" and current_x <= x"81") then --
            colorOut <= GREEN;
        end if;

        if(current_y > x"111" and current_y <= x"114" and current_x >= x"FB" and current_x <= x"1F1") then --
            colorOut <= GREEN;
        end if;

        if(current_y > x"143" and current_y <= x"146" and current_x >= x"A6" and current_x <= x"1F1") then --
            colorOut <= GREEN;
        end if;

        if(current_y > x"143" and current_y <= x"196" and current_x >= x"1F1" and current_x <= x"1F4") then --
            colorOut <= GREEN;
        end if;

        if(current_y > x"143" and current_y <= x"161" and current_x >= x"A6" and current_x <= x"A9") then --
        end if;

        if(current_y > x"161" and current_y <= x"164" and current_x >= x"7E" and current_x <= x"A6") then --
            colorOut <= GREEN;
        end if;

        if(current_y > x"161" and current_y <= x"164" and current_x >= x"7E" and current_x <= x"A6") then --
            colorOut <= GREEN;
        end if;
        
        if(current_y > x"196" and current_y <= x"199" and current_x >= x"E7" and current_x <= x"1F1") then --
            colorOut <= GREEN;
        end if;

        if(current_y > x"196" and current_y <= x"1AA" and current_x >= x"E7" and current_x <= x"EA") then --
            colorOut <= GREEN;
        end if;

        if(current_y > x"1A5" and current_y <= x"1AA" and current_x >= x"E7" and current_x <= x"205") then --
            colorOut <= GREEN;
        end if;       
    end if;    
     
--     if(level ='1') then
--           if(current_y > x"3F" and current_y <= x"8F" and current_x >= x"7E" and current_x <= x"81") then 
--                 colorOut <= GREEN;
--             end if;
             
--             if(current_y > x"3F" and current_y <= x"42" and current_x >= x"7E" and current_x <= x"FB") then 
--                 colorOut <= GREEN;
--             end if;        
             
--             if(current_y > x"3F" and current_y <= x"A3" and current_x >= x"FB" and current_x <= x"FF") then 
--                 colorOut <= GREEN;
--             end if;        
     
--             if(current_y > x"3F" and current_y <= x"111" and current_x >= x"1F1" and current_x <= x"1F4") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"3F" and current_y <= x"42" and current_x >= x"1F1" and current_x <= x"205") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"3F" and current_y <= x"1A5" and current_x >= x"205" and current_x <= x"208") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"53" and current_y <= x"8F" and current_x >= x"92" and current_x <= x"95") then 
--                 colorOut <= GREEN;
--             end if;
             
--             if(current_y > x"53" and current_y <= x"56" and current_x >= x"92" and current_x <= x"E7") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"53" and current_y <= x"B7" and current_x >= x"E7" and current_x <= x"EA") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"67" and current_y <= x"A3" and current_x >= x"141" and current_x <= x"144") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"67" and current_y <= x"6A" and current_x >= x"141" and current_x <= x"1A4") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"67" and current_y <= x"F8" and current_x >= x"1A4" and current_x <= x"1A7") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"7B" and current_y <= x"B7" and current_x >= x"15F" and current_x <= x"162") then 
--                  colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"7B" and current_y <= x"7E" and current_x >= x"15F" and current_x <= x"190") then 
--                  colorOut <= GREEN;
--             end if;        
     
--             if(current_y > x"7B" and current_y <= x"DF" and current_x >= x"190" and current_x <= x"193") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"7B" and current_y <= x"7E" and current_x >= x"15F" and current_x <= x"190") then 
--                  colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"8F" and current_y <= x"92" and current_x >= x"7E" and current_x <= x"92") then 
--                  colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"A3" and current_y <= x"A6" and current_x >= x"FB" and current_x <= x"141") then 
--                  colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"B7" and current_y <= x"BA" and current_x >= x"E7" and current_x <= x"15F") then 
--                  colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"DF" and current_y <= x"111" and current_x >= x"E7" and current_x <= x"EA") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"DF" and current_y <= x"E2" and current_x >= x"E7" and current_x <= x"190") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"F8" and current_y <= x"FB" and current_x >= x"FB" and current_x <= x"1A4") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"F8" and current_y <= x"111" and current_x >= x"FB" and current_x <= x"FE") then 
--                 colorOut <= GREEN;
--             end if;
             
--             if(current_y > x"143" and current_y <= x"161" and current_x >= x"A6" and current_x <= x"A9") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"111" and current_y <= x"114" and current_x >= x"7E" and current_x <= x"E7") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"111" and current_y <= x"161" and current_x >= x"7E" and current_x <= x"81") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"111" and current_y <= x"114" and current_x >= x"FB" and current_x <= x"1F1") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"143" and current_y <= x"146" and current_x >= x"A6" and current_x <= x"1F1") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"143" and current_y <= x"196" and current_x >= x"1F1" and current_x <= x"1F4") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"143" and current_y <= x"161" and current_x >= x"A6" and current_x <= x"A9") then 
--             end if;
     
--             if(current_y > x"161" and current_y <= x"164" and current_x >= x"7E" and current_x <= x"A6") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"161" and current_y <= x"164" and current_x >= x"7E" and current_x <= x"A6") then 
--                 colorOut <= GREEN;
--             end if;
             
--             if(current_y > x"196" and current_y <= x"199" and current_x >= x"E7" and current_x <= x"1F1") then 
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"196" and current_y <= x"1AA" and current_x >= x"E7" and current_x <= x"EA") then
--                 colorOut <= GREEN;
--             end if;
     
--             if(current_y > x"1A5" and current_y <= x"1AA" and current_x >= x"E7" and current_x <= x"205") then
--                 colorOut <= GREEN;
--             end if;
--     end if;
     else -- Off display
        colorOut <= BLUE;
    end if;   
   end process;

Count: process(clk, rst)
begin
    if(rst='1')then
        counterSec <= (others=> '0');
        top_time <= timer_trial;
        trial <= timer_trial;
        score <= (others => '0');
        level <= '0';
    elsif(clk'event and clk = '1') then
     counterSec <= counterSec +'1';
     if(counterSec = "000000000000000000000000000") then 
            top_time <= top_time - x"008";
            score <= score  +'1';
            if(top_time = x"7B") then
                top_time <= timer_trial;
                trial <= trial-x"87";
            end if;
        end if;
    end if;
end process;

HUMAN_PLAYER:process(rst, clk)
begin
  if(rst = '1') then
      bottom_player_y1 <= bottom_border - x"0f"; 
      bottom_player_x1 <= left_border + x"90";
      hallway <= "00000";
      
    elsif(clk'event and clk = '1') then
    if(endOfFrame = '1') then
    
        if(hallway= "00000") then
               if(btnL = '1' and  bottom_player_x1 >= x"EA") then
                 bottom_player_x1 <= bottom_player_x1 - '1';
               elsif(btnR = '1') then
                 bottom_player_x1 <= bottom_player_x1 + '1';
               end if;
               if(btnD = '1' and  bottom_player_y2 <= x"1A5") then
                 bottom_player_y1 <= bottom_player_y1 + '1';
               elsif(btnU = '1' and  bottom_player_y1 >= x"199") then
                   bottom_player_y1 <= bottom_player_y1 - '1';
               end if;
               if(bottom_player_x1 >= x"1F4") then
               hallway <= "00001";
               end if;
          end if;
          
        if(hallway= "00001") then
                 if(btnL = '1' and  bottom_player_x1 >= x"EA") then
                   bottom_player_x1 <= bottom_player_x1 - '1';
                 elsif(btnR = '1' and bottom_player_x2 <= x"205") then
                   bottom_player_x1 <= bottom_player_x1 + '1';
                 end if;
                 if(btnD = '1' and  bottom_player_y2 <= x"1A5") then
                   bottom_player_y1 <= bottom_player_y1 + '1';
                 elsif(btnU = '1') then
                     bottom_player_y1 <= bottom_player_y1 - '1';
                 end if;
                 if(bottom_player_x2 <= x"1F4") then
                 hallway <= "00000";
                 end if;
                 if(bottom_player_y2 <= x"199") then 
                    hallway <= "00010";
                    end if;
            end if;          

        if(hallway= "00010") then
               if(btnL = '1' and  bottom_player_x1 >= x"1F4") then
                 bottom_player_x1 <= bottom_player_x1 - '1';
               elsif(btnR = '1' and bottom_player_x2 <= x"205") then
                 bottom_player_x1 <= bottom_player_x1 + '1';
               end if;
               if(btnD = '1') then
                 bottom_player_y1 <= bottom_player_y1 + '1';
               elsif(btnU = '1') then
                   bottom_player_y1 <= bottom_player_y1 - '1';
               end if;
               if(bottom_player_y1 >= x"199") then
               hallway <= "00001";
               end if;
               if(bottom_player_y2 <= x"143") then
               hallway <= "00011";
               end if;
          end if;          

        if(hallway= "00011") then
               if(btnL = '1') then
                 bottom_player_x1 <= bottom_player_x1 - '1';
               elsif(btnR = '1' and bottom_player_x2 <= x"205") then
                 bottom_player_x1 <= bottom_player_x1 + '1';
               end if;
               if(btnD = '1') then
                 bottom_player_y1 <= bottom_player_y1 + '1';
               elsif(btnU = '1') then
                   bottom_player_y1 <= bottom_player_y1 - '1';
               end if;
               if(bottom_player_y2 <= x"114") then
               hallway <= "00100";
               end if;
               if(bottom_player_y1 >= x"143") then
               hallway <= "00010";
               end if;
               if(bottom_player_x2 <= x"1F4") then
               hallway <= "00101";
               end if;
          end if;       

        if(hallway= "00100") then
               if(btnL = '1' and  bottom_player_x1 >= x"1F4") then
                 bottom_player_x1 <= bottom_player_x1 - '1';
               elsif(btnR = '1' and bottom_player_x2 <= x"205") then
                 bottom_player_x1 <= bottom_player_x1 + '1';
               end if;
               if(btnD = '1') then
                 bottom_player_y1 <= bottom_player_y1 + '1';
               elsif(btnU = '1' and  bottom_player_y1 >= x"42") then
                   bottom_player_y1 <= bottom_player_y1 - '1';
               end if;
               if(bottom_player_y1 >= x"114") then
               hallway <= "00011";
               end if;
          end if;
          
        if(hallway= "00101") then
               if(btnL = '1') then
                 bottom_player_x1 <= bottom_player_x1 - '1';
               elsif(btnR = '1') then
                 bottom_player_x1 <= bottom_player_x1 + '1';
               end if;
               if(btnD = '1' and  bottom_player_y2 <= x"143") then
                 bottom_player_y1 <= bottom_player_y1 + '1';
               elsif(btnU = '1' and  bottom_player_y1 >= x"114") then
                   bottom_player_y1 <= bottom_player_y1 - '1';
               end if;
               if(bottom_player_x1 >= x"1F4")then
               hallway <= "00011";
               end if;
               if(bottom_player_x2 <= x"FB") then
               hallway <= "00110";
               end if;
          end if; 

        if(hallway= "00110") then
               if(btnL = '1') then
                 bottom_player_x1 <= bottom_player_x1 - '1';
               elsif(btnR = '1') then
                 bottom_player_x1 <= bottom_player_x1 + '1';
               end if;
               if(btnD = '1' and  bottom_player_y2 <= x"143") then
                 bottom_player_y1 <= bottom_player_y1 + '1';
               elsif(btnU = '1') then
                   bottom_player_y1 <= bottom_player_y1 - '1';
               end if;
               if(bottom_player_x1 >= x"FB") then
               hallway <= "00101";
               end if;
               if(bottom_player_x2 <= x"EA") then
               hallway <= "01000";
               end if;
               if(bottom_player_y2 <= x"114") then
               hallway <= "00111";
               end if;
          end if; 

        if(hallway= "00111") then
               if(btnL = '1' and  bottom_player_x1 >= x"EA") then
                 bottom_player_x1 <= bottom_player_x1 - '1';
               elsif(btnR = '1' and bottom_player_x2 <= x"FB") then
                 bottom_player_x1 <= bottom_player_x1 + '1';
               end if;
               if(btnD = '1') then
                 bottom_player_y1 <= bottom_player_y1 + '1';
               elsif(btnU = '1') then
                   bottom_player_y1 <= bottom_player_y1 - '1';
               end if;
               if(bottom_player_y1 >= x"114") then
               hallway <= "00110";
               end if;
          end if;    

        if(hallway= "01000") then
               if(btnL = '1' and  bottom_player_x1 >= x"81") then
                 bottom_player_x1 <= bottom_player_x1 - '1';
               elsif(btnR = '1') then
                 bottom_player_x1 <= bottom_player_x1 + '1';
               end if;
               if(btnD = '1') then
                 bottom_player_y1 <= bottom_player_y1 + '1';
               elsif(btnU = '1' and  bottom_player_y1 >= x"114") then
                   bottom_player_y1 <= bottom_player_y1 - '1';
               end if;
               if(bottom_player_x1 >= x"EA") then
               hallway <= "00110";
               end if;
               if(bottom_player_y1 >= x"143") then
               hallway <= "10001";
               level<= '1';
               end if;
          end if;     
   
        if(hallway= "01001") then
           if(btnL = '1' and  bottom_player_x1 >= x"81") then
             bottom_player_x1 <= bottom_player_x1 - '1';
           elsif(btnR = '1' and bottom_player_x2 <= x"EA") then
             bottom_player_x1 <= bottom_player_x1 + '1';
           end if;
           if(btnD = '1' and  bottom_player_y2 <= x"161") then
             bottom_player_y1 <= bottom_player_y1 + '1';
           elsif(btnU = '1') then
               bottom_player_y1 <= bottom_player_y1 - '1';
           end if;
           if(bottom_player_y2 <= x"143") then
           hallway <= "01000";
           end if;
      end if;
      
      end if;      
      end if;
end process;

bottom_player_x2 <= bottom_player_x1 + x"8";
bottom_player_y2 <= bottom_player_y1 + x"8";

end behavioral;