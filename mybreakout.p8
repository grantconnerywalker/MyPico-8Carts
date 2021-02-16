pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
function _init()
 cls()	
	// state
	loser=false
	playsfx=false
	message=""	
	mode="start"
end

function _update60()
	if mode=="game" then
		update_game()
	elseif mode=="start" then
		update_start()
	elseif mode=="gameover" then
  update_gameover()
	end
end

function _draw()
	if mode=="game" then
		draw_game()
	elseif mode=="start" then
		draw_start()
	elseif mode=="gameover" then
		draw_gameover()
	end
end

--------------------------------
---- user defined functions ----
--------------------------------
function update_game()
	local nextx, nexty

	move_paddle()

	nextx=ball_x+ball_dx
	nexty=ball_y+ball_dy
	
	if ball_box(nextx,nexty,pad_x,pad_y,pad_w,pad_h) then
		-- find out which direction to deflect
  if deflx_ball_box(ball_x,ball_y,ball_dx,ball_dy,pad_x,pad_y,pad_w,pad_h) then
   ball_dx = -ball_dx
  else
   ball_dy = -ball_dy
  end
		score+=1
		sfx(1)
	end
			
	ball_x=nextx
	ball_y=nexty
	
	// this is where we check
	// if the ball hits the edges
	if nextx > 127 or nextx < 0 then
		nextx=mid(0,nextx,127)
		ball_dx=-ball_dx
		sfx(0)
	end
	if nexty < (banner+2) then
		nexty=mid(0,nexty,127)
		ball_dy=-ball_dy
		sfx(0)
	elseif nexty > 129 then
		lives-=1
		if lives < 0 then
			gameover()
		else
			sfx(3)
			serveball()
		end
	end
		
end

function update_start()
	if btn(5) then
		startgame()
	end
end

function update_gameover()
	if btn(5) then
		startgame()
	end
end

function draw_game()
	-- fill background
	cls(1)
	
	-- draw updates
	print(message, 0, 0, 8)
 circfill(ball_x,ball_y,ball_r,ball_color)
	rectfill(pad_x,pad_y,pad_x+pad_w,pad_y+pad_h,7)
	
	rectfill(0,0,128,banner,0)
	print("lives:"..lives,1,1,7)
	print("score:"..score,40,1,7)
end

function draw_start()
	cls(1)
	print("pico hero breakout",30,40,7)
	print("press ❎ to start",32,80,11)
end

function draw_gameover()
	rectfill(0,60,128,75,0)
	print("game over!",47,62,7)
		print("press ❎ to restart",30,68,6)
end

function startgame()
	mode="game"
	
	banner=6 -- banner height
	
	ball_x=1 --position
	ball_y=64
	ball_dx=1 -- speed
	ball_dy=1
	ball_r=2 --radius
	ball_dr=0.5
	ball_color=10 --color
	
	pad_x=52
	pad_y=120
	pad_dx=0
	pad_w=24
	pad_h=3
	
	lives=3
	score=0
end

function gameover()
	sfx(2)
	mode="gameover"
end

function serveball()
	ball_x=1 --position
	ball_y=64
	ball_dx=1 -- speed
	ball_dy=1
end

// paddle movement
function move_paddle()
	local buttpress=false
	local pad_speed=2.5
	if btn(0) then
		-- left
		pad_dx=-pad_speed
		buttpress=true
	end
	if btn(1) then
		-- right
		pad_dx=pad_speed
		buttpress=true
	end
	-- deceleration
	if not(buttpress) then
		pad_dx/=1.3 -- make this into variable pad_decel
	end
	pad_x+=pad_dx
	
	-- keep paddle in walls
	if pad_x+pad_w>127 then
		pad_x=127-pad_w
	end
	if pad_x<0 then
		pad_x=0
	end
end

// ball and paddle collision
function ball_box(bx,by,box_x,box_y,box_w,box_h)
	if by-ball_r > box_y+box_h then	return false end
	if by+ball_r < box_y then	return false end
	if bx-ball_r > box_x+box_w then	return false end
	if bx+ball_r < box_x then	return false end
	return true
end

// deflect if hit edge
function deflx_ball_box(bx,by,bdx,bdy,tx,ty,tw,th)
 -- calculate wether to deflect the ball
 -- horizontally or vertically when it hits a box
 if bdx == 0 then
  -- moving vertically
  return false
 elseif bdy == 0 then
  -- moving horizontally
  return true
 else
  -- moving diagonally
  -- calculate slope
  local slp = bdy / bdx
  local cx, cy
  -- check variants
  if slp > 0 and bdx > 0 then
   -- moving down right
   debug1="q1"
   cx = tx-bx
   cy = ty-by
   if cx<=0 then
    return false
   elseif cy/cx < slp then
    return true
   else
    return false
   end
  elseif slp < 0 and bdx > 0 then
   debug1="q2"
   -- moving up right
   cx = tx-bx
   cy = ty+th-by
   if cx<=0 then
    return false
   elseif cy/cx < slp then
    return false
   else
    return true
   end
  elseif slp > 0 and bdx < 0 then
   debug1="q3"
   -- moving left up
   cx = tx+tw-bx
   cy = ty+th-by
   if cx>=0 then
    return false
   elseif cy/cx > slp then
    return false
   else
    return true
   end
  else
   -- moving left down
   debug1="q4"
   cx = tx+tw-bx
   cy = ty-by
   if cx>=0 then
    return false
   elseif cy/cx < slp then
    return false
   else
    return true
   end
  end
 end
 return false
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000143501434014340143301333012320123101d3000d300203001e3001c3001a30019300183001630014300143001820019200192001a2001b2001b2001c2001c2001c2001c2001c2001c2001c20025700
000100002405024050240502405024050240402404024040240400f0001c0001f0001e000140000e0000c00019000200001f000200000d0000c0002700020000210002a0000c0000e0002a000210002100000000
000f00002d030290302603023030000002903026030220301f0300000025030220301f0301d030000000f0300c0300d0300d0300d0300d0300000000000000000000000000000000000000000000000000000000
0002000026450214501a45014450114500e4500b45008450074500545004450044500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
