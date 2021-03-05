pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
// goals
// 2. wide paddle powerup?
// 3. angle control
// 3a. combos
// 4. levels
// 5. different bricks
// 5a. powerups
// 6. juiciness (particles/shake)
// 8. high score

function _init()
	cls()	
	// state
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
	local nextx,nexty,brickhit

	move_paddle()

	if sticky then
		ball_x=pad_x+flr(pad_w/2)
		ball_y=pad_y-ball_r-1
	else
		nextx=ball_x+ball_dx
		nexty=ball_y+ball_dy
		
		-- check if ball hit pad	
		if ball_box(nextx,nexty,pad_x,pad_y,pad_w,pad_h) then
			-- find out which direction to deflect
			if deflx_ball_box(ball_x,ball_y,ball_dx,ball_dy,pad_x,pad_y,pad_w,pad_h) then
				-- ball hit paddle on the side
				ball_dx = -ball_dx
				if ball_x < pad_x+pad_w/2 then
					nextx=pad_x-ball_r
				else
					nextx=pad_x+pad_w+ball_r
				end
			else
				-- ball hit paddle on the top/bottom
				ball_dy = -ball_dy
				if ball_y > pad_y then
					-- bottom
					nexty=pad_y+pad_h+ball_r
				else
					-- top
					nexty=pad_y-ball_r
					if abs(pad_dx) > 2 then
						-- change angle
						if sign(pad_dx)==sign(ball_dx) then
							-- flatten angle
							setang(mid(0,ball_ang-1,2))
						else
							-- raise angle
							if ball_ang==2 then
								ball_dx=-ball_dx
							else
								setang(mid(0,ball_ang+1,2))
							end
						end
					end
				end
			end
			score+=1
			sfx(1)
		end
		
		-- check if ball hit brick
		brickhit=false
		for i=1,#brick_x do
			if brick_v[i] and ball_box(nextx,nexty,brick_x[i],brick_y[i],brick_w,brick_h) then
				-- find out which direction to deflect
				if not(brickhit) then
					if deflx_ball_box(ball_x,ball_y,ball_dx,ball_dy,brick_x[i],brick_y[i],brick_w,brick_h) then
						ball_dx = -ball_dx
					else
						ball_dy = -ball_dy
					end
				end
				brickhit=true
				score+=10
				brick_v[i]=false
				sfx(5)
			end
		end
		
		-- check if win
		local finish=true
		for i=1,#brick_v do
			if brick_v[i] then finish = false end
		end
		if finish then gameover() end
		ball_x=nextx
		ball_y=nexty
		
		-- this is where we check
		--- if the ball hits the edges
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
	
	-- draw ball and paddle
	print(message, 0, 0, 8)
	circfill(ball_x,ball_y,ball_r,ball_color)
	if sticky then
		-- serve preview, not sure why need - on the y's
		line(ball_x+ball_dx*4,ball_y-ball_dy*4,ball_x+ball_dx*6,ball_y-ball_dy*6,10)
	end
	rectfill(pad_x,pad_y,pad_x+pad_w,pad_y+pad_h,7)
	
	-- draw bricks
	for i=1,#brick_x do
		if brick_v[i] then
			rectfill(brick_x[i],brick_y[i],brick_x[i]+brick_w,brick_y[i]+brick_h,brick_c)
		end
	end
	
	rectfill(0,0,128,banner,0)
	print("lives:"..lives,1,1,7)
	print("score:"..score,40,1,7)
	print("debug:"..debug1,80,1,7)
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
	ball_ang=1
	
	pad_x=52
	pad_y=120
	pad_dx=0
	pad_w=24
	pad_h=3
	
	brick_x={}
	brick_y={}
	brick_v={}
	brick_w=9
	brick_h=4
	brick_c=14
	buildbricks()
	
	lives=3
	score=0
	
	sticky=true
	
	--debug
	debug1=""
end
	
function buildbricks()
	local i
	brick_x={}
	brick_y={}
	brick_v={}
	for i=1,66 do
		add(brick_x,4+((i-1)%11)*(brick_w+2)) --increment 60
		add(brick_y,20+flr((i-1)/11)*(brick_h+2))
		add(brick_v,true)
	end
end
	
function gameover()
	sfx(2)
	mode="gameover"
end
	
function serveball()
	ball_x=pad_x+flr(pad_w/2)
	ball_y=pad_y-ball_r-pad_h
	ball_dx=1
	ball_dy=-1
	ball_ang=1
	sticky=true
	
end
	
function setang(ang)
	--0.5
	--1.30 angle transform values
	ball_ang=ang
	if ang==2 then
		ball_dx=0.5*sign(ball_dx)
		ball_dy=1.3*sign(ball_dy)
	elseif ang==0 then
		ball_dx=1.3*sign(ball_dx)
		ball_dy=0.5*sign(ball_dy)	
	else
		ball_dx=1*sign(ball_dx)
		ball_dy=1*sign(ball_dy)
	end
end
	
function sign(n)
	if n<0 then
		return -1
		elseif n>0 then
		return 1
		else
		return 0
	end
end
	
// paddle movement
function move_paddle()
	local buttpress=false
	local pad_speed=2.5
	if btn(0) then
		-- left
		pad_dx=-pad_speed
		buttpress=true
		if sticky then
			ball_dx=-1
		end
	end
	if btn(1) then
		-- right
		pad_dx=pad_speed
		buttpress=true
		if sticky then
			ball_dx=1
		end
	end
	if sticky and btnp(5) then
		sticky=false
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
	local slp = bdy / bdx
	local cx, cy
	if bdx == 0 then return false
	elseif bdy == 0 then return true
	elseif slp > 0 and bdx > 0 then
		cx = tx - bx
		cy = ty - by
		return cx > 0 and cy/cx < slp
	elseif slp < 0 and bdx > 0 then
		cx = tx - bx
		cy = ty + th - by
		return cx > 0 and cy/cx >= slp
	elseif slp > 0 and bdx < 0 then
		cx = tx + tw - bx
		cy = ty + th - by
		return cx < 0 and cy/cx <= slp
	else
		cx = tx + tw - bx
		cy = ty - by
		return cx < 0 and cy/cx >= slp
	end
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
000300000965008650086500765006650066500665022600236002560026600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300003b35039350383502635015350013500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003a0003a0003a0003a0003a0003a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
