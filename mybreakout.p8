pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
ball_x=1 --position
ball_y=64
ball_dx=2 -- speed
ball_dy=2
ball_r=2 --radius
ball_dr=0.5
ball_color=10 --color
frame=0

// these 13 executed every frame
function _init()
 cls()
end

function _update()
	frame=frame+1
	ball_x=ball_x+ball_dx
	ball_y=ball_y+ball_dy
--	ball_r=2+sin(frame)
	
	// this is where we check
	// if the heart hits the edges
	if ball_x > 127 or ball_x < 0 then
		ball_dx=-ball_dx
		sfx(0)
	end
	if ball_y > 127 or ball_y < 0 then
		ball_dy=-ball_dy
		sfx(0)
	end
--	if ball_r > 2 or ball_r < 1 then
--		ball_dr=-ball_dr
--	end
end

function _draw()
	rectfill(0,0,127,127,1)
 circfill(ball_x,ball_y,ball_r,ball_color)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001a3501a350193501934019340193301b3001d3000d300203001e3001c3001a30019300183001630014300143001820019200192001a2001b2001b2001c2001c2001c2001c2001c2001c2001c20025700
