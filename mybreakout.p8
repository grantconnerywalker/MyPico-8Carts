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

pad_x=52
pad_y=120
pad_dx=0
pad_w=24
pad_h=3

// these 13 executed every frame
function _init()
 cls()
end

function _update()
	buttpress=false
	if btn(0) then
		-- left
		pad_dx=-5
		buttpress=true
	end
	if btn(1) then
		-- right
		pad_dx=5
		buttpress=true
	end
	-- deceleration
	if not(buttpress) then
		pad_dx/=1.75 -- make this into variable pad_decel
	end
	pad_x+=pad_dx
	
	-- keep paddle in walls
	if pad_x+pad_w>127 then
		pad_x=127-pad_w
	end
	if pad_x<0 then
		pad_x=0
	end

	-- collision detection
	-- todo

	ball_x+=ball_dx
	ball_y+=ball_dy
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

	if ball_box(pad_x,pad_y,pad_w,pad_h) then
		-- todo handle collision
		ball_dy*=-1
		sfx(1)
	end
end

function _draw()
	rectfill(0,0,127,127,1)
 circfill(ball_x,ball_y,ball_r,ball_color)
	rectfill(pad_x,pad_y,pad_x+pad_w,pad_y+pad_h,7)
end

// ball and paddle collision
function ball_box(box_x,box_y,box_w,box_h)
	if ball_y-ball_r > box_y+box_h then
		return false
	end
	if ball_y+ball_r < box_y then
		return false
	end
	if ball_x-ball_r > box_x+box_w then
		return false
	end
	if ball_x+ball_r < box_x then
		return false
	end
	return true
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
000100000945008450084500845008450084500845008450094500f0001c0001f0001e000140000e0000c00019000200001f000200000d0000c0002700020000210002a0000c0000e0002a000210002100000000
