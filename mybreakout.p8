pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
// goals
// 6. juiciness (particles/shake)
// 8. high score

function _init()
	cls()	
	// state
	message=""	
	mode="start"
	level="xxxxxb"
	levelnum = 1
	levels={}
	--levels[1]="xxxxxb"
	--levels[2]="bxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbx"
	--levels[1]="////x4b/s9s"
	levels[1]="i9b/p9p"
	
		--debug
	debug1=""
end

function _update60()
	if mode=="game" then
		update_game()
	elseif mode=="start" then
		update_start()
	elseif mode=="gameover" then
		update_gameover()
	elseif mode=="levelover" then
		update_levelover()
	end
end

function _draw()
	if mode=="game" then
		draw_game()
	elseif mode=="start" then
		draw_start()
	elseif mode=="gameover" then
		draw_gameover()
	elseif mode=="levelover" then
		draw_levelover()
	end
end

--------------------------------
---- user defined functions ----
--------------------------------
function update_game()
	local nextx,nexty,brickhit

	-- check if pad should grow
	if powerup==4 then
		-- todo gradual growth
		pad_w=flr(pad_wo*1.5)
	elseif powerup==5 then
		-- check if pad should shrink
		pad_w=flr(pad_wo/2)
		pointsmult=2
	else
		pad_w=pad_wo
	end

	move_paddle()

	-- big ball loop
	for i=#ball,1,-1 do
		updateball(ball[i])
	end
	
	-- move pills
	-- check pill collision
	for i=#pills,1,-1 do
		pills[i].y+=0.7
		if pills[i].y > 128 then
			-- remove pill
			del(pills,pills[i])
		elseif box_box(pills[i].x,pills[i].y,8,6,pad_x,pad_y,pad_w,pad_h) then
			powerupget(pills[i].t)
			-- remove pill
			del(pills,pills[i])
			sfx(12)
		end
	end

	
	checkexplosions()
	
	if powerup!=0 then
		powerup_t-=1
		if powerup_t<=0 then
			powerup=0
		end 
	end
end

function updateball(b)
	
	if b.stuck then
		--ball_x=pad_x+flr(pad_w/2)
		-- only sticky for first ball for now
	 b.x=pad_x+sticky_x
		b.y=pad_y-ball_r-1
	else
		--regular ball physics
		if powerup==1 then
			nextx=b.x+(b.dx/2)
			nexty=b.y+(b.dy/2)
		else
			nextx=b.x+b.dx
			nexty=b.y+b.dy
		end
		
		-- check if ball hit pad	
		if ball_box(nextx,nexty,pad_x,pad_y,pad_w,pad_h) then
			-- find out which direction to deflect
			if deflx_ball_box(b.x,b.y,b.dx,b.dy,pad_x,pad_y,pad_w,pad_h) then
				-- ball hit paddle on the side
				b.dx = -b.dx
				if b.x < pad_x+pad_w/2 then
					nextx=pad_x-ball_r
				else
					nextx=pad_x+pad_w+ball_r
				end
			else
				-- ball hit paddle on the top/bottom
				b.dy = -b.dy
				if b.y > pad_y then
					-- bottom
					nexty=pad_y+pad_h+ball_r
				else
					-- top
					nexty=pad_y-ball_r
					if abs(pad_dx) > 2 then
						-- change angle
						if sign(pad_dx)==sign(b.dx) then
							-- flatten angle
							setang(b,mid(0,b.ang-1,2))
						else
							-- raise angle
							if b.ang==2 then
								b.dx=-b.dx
							else
								setang(b,mid(0,b.ang+1,2))
							end
						end
					end
				end
			end
			
			score+=multiplier*pointsmult
			multiplier=1
			sfx(1)
			
			--catch powerup
			if sticky and b.dy<0 then	
				releasestuck()
				sticky = false
				b.stuck = true
				sticky_x = b.x-pad_x
			end
		end
		
		-- check if ball hit brick
		brickhit=false
		for i=1,#bricks do
			if bricks[i].v and ball_box(nextx,nexty,bricks[i].x,bricks[i].y,brick_w,brick_h) then
				-- find out which direction to deflect
				if not(brickhit) then
					if (powerup != 6) 
					or (powerup == 6 and bricks[i].t=="i") then 
						if deflx_ball_box(b.x,b.y,b.dx,b.dy,bricks[i].x,bricks[i].y,brick_w,brick_h) then
							b.dx = -b.dx
						else
							b.dy = -b.dy
						end
					end
				end
				brickhit=true
				hitbrick(i,true)
			end
		end
		
		-- check if win
		if levelfinished() then
			_draw()
			levelover()
		end
		
		-- move ball
		b.x=nextx
		b.y=nexty
		
		-- this is where we check
		--- if the ball hits the edges
		if nextx > 127 or nextx < 0 then
			nextx=mid(0,nextx,127)
			b.dx=-b.dx
			sfx(0)
		end
		if nexty < (banner+2) then
			nexty=mid(0,nexty,127)
			b.dy=-b.dy
			sfx(0)
		elseif nexty > 129 then
			if #ball > 1 then
				del(ball,b)
			else
				lives-=1
				if lives < 0 then
					gameover()
				else
					sfx(3)
					serveball()
				end
			end
		end
		
	end -- end of sticky if
end

function releasestuck()
	for i=1,#ball do
		if ball[i].stuck then
			ball[i].x = mid(0,ball[i].x,127)
			ball[i].stuck = false
		end
	end	
end

function pointstuck(sign)
	for i=1,#ball do
		if ball[i].stuck then
			ball[i].dx = abs(ball[i].dx)*sign
		end
	end	
end

function powerupget(_p)
	if _p==1 then
		-- slow down
		powerup=1
		powerup_t=900
	elseif _p==2 then
		-- life
		powerup=2
		powerup_t=0
		lives+=1
	elseif _p==3 then
	 -- catch
	 -- check if there are stuck balls
	 hasstuck=false
	 for i=1,#ball do
	 	if ball[i].stuck then
	 		hasstuck=true
	 	end
	 end
	 if hasstuck==false then
	 	sticky=true
	 end
		--powerup=3
		--powerup_t=900 -- frames/10 seconds
	elseif _p==4 then
		-- expand
		powerup=4
		powerup_t=900
	elseif _p==5 then
		-- reduce
		powerup=5
		powerup_t=900
	elseif _p==6 then
		-- megaball
		powerup=6
		powerup_t=900
	elseif _p==7 then
		-- multiball
		--powerup=7
		--powerup_t=900
		releasestuck()
		multiball()
	end
end

-- todo fix indestructible b
function hitbrick(_i,_combo)
	if bricks[_i].t == "b" then
		bricks[_i].v=false
		if _combo then
			score+=10*multiplier*pointsmult
			multiplier+=1
		end
		if multiplier>5 then
			sfx(6)
		elseif multiplier>15 then
			sfx(7)
		else
			sfx(5)
		end
	elseif bricks[_i].t == "i" then
		sfx(9)
	elseif bricks[_i].t == "h" then
		if powerup==6 then
			brick_v[_i]=false
			if _combo then
				score+=10*multiplier*pointsmult
				multiplier+=1
				if multiplier>5 then
					sfx(6)
				elseif multiplier>15 then
					sfx(7)
				else
					sfx(5)
				end
			end
		else
			sfx(10)
			bricks[_i].t = "b"
		end
	elseif bricks[_i].t == "p" then
		sfx(7)
		if _combo then
			score+=multiplier*pointsmult
			multiplier+=1
		end
		bricks[_i].v=false
		spawnpill(bricks[_i].x,bricks[_i].y)
	elseif bricks[_i].t == "s" then
		--splode sfx (pink?)
		sfx(11)
		bricks[_i].t="zz"
		if _combo then
			score+=multiplier*pointsmult
			multiplier+=1
		end
	end
end

function spawnpill(_x,_y)
	-- 7 because 7 powerups
	local _t
	local _pill
	--_t =	flr(rnd(7)+1)
	-- for testing only
	_t =	flr(rnd(2))
	if _t == 0 then
		_t = 3
	else
	 _t = 7
	end
 -- for testing only
 
 _pill={}
 _pill.x=_x
 _pill.y=_y
 _pill.t=_t
 add(pills,_pill)
end

function checkexplosions()
	for i=1,#bricks do
		if bricks[i].t == "zz" then
			bricks[i].t = "z"
		end
	end

	for i=1,#bricks do
		if bricks[i].t == "z" then
			explodebrick(i)
		end
	end
	
	for i=1,#bricks do
		if bricks[i].t == "zz" then
			bricks[i].t = "z"
		end
	end
end

function explodebrick(_i)
	bricks[_i].v=false
	for j=1,#brick do
		if j!=_i and bricks[j].v 
		and abs(bricks[j].x-bricks[_i].x) <= (brick_w+2)
		and abs(bricks[j].y-bricks[_i].y) <= (brick_h+2)
		then
			hitbrick(j, false)
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

function update_levelover()
	if btn(5) then
		nextlevel()
	end
end

function draw_game()
	-- fill background
	cls(1)
	
	-- draw ball and paddle
	print(message, 0, 0, 8)
	for i=1,#ball do
			circfill(ball[i].x,ball[i].y,ball_r,ball_color)
			if ball[i].stuck then
				line(ball[i].x+ball[i].dx*4,ball[i].y-ball[i].dy*4,ball[i].x+ball[i].dx*6,ball[i].y+ball[i].dy*6,10)
			end
	end

	rectfill(pad_x,pad_y,pad_x+pad_w,pad_y+pad_h,7)
	
	-- draw bricks
	for i=1,#bricks do
		if bricks[i].v then
			if bricks[i].t == "b" then
				brickcol = 14
			elseif bricks[i].t == "i" then
				brickcol = 15
			elseif bricks[i].t == "h" then
				brickcol = 6
			elseif bricks[i].t == "s" then
				brickcol = 8
			elseif bricks[i].t == "p" then
				brickcol = 12
			--this type for debug only
			elseif bricks[i].t == "z" or bricks[i].t == "zz" then
				brickcol = 3
			end
			rectfill(bricks[i].x,bricks[i].y,bricks[i].x+brick_w,bricks[i].y+brick_h,brickcol)
		end
	end
	
	-- draw pills
	for i=1,#pills do
		if pills[i].t==5 then
			palt(0,false)
			palt(15,true)
		end
		spr(pills[i].t,pills[i].x,pills[i].y)
		palt()
	end
	
	rectfill(0,0,128,banner,0)
	if debug1!="" then
		print("debug:"..debug1,1,1,7)
	else
		print("lives:"..lives,1,1,7)
		print("score:"..score,40,1,7)
	--	print("debug:"..debug1,80,1,7)
	end
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

function draw_levelover()
	rectfill(0,60,128,75,0)
	print("stage clear!",47,62,7)
	print("press ❎ to continue",30,68,6)
end


function startgame()
	mode="game"
	
	banner=6 -- banner height
	
	pad_x=52
	pad_y=120
	pad_dx=0
	pad_wo=24 -- constant original pad width
	pad_w=24 -- current pad width
	pad_h=3
	
	-- reset ball
	--ball_x=1 --position
	--ball_y=64
	--ball_dx=1 -- speed
	--ball_dy=1
	ball_r=2 --radius
	ball_dr=0.5
	ball_color=10 --color
	ball_ang=1
	ball={}
	ball[1] = newball()
	
	brick_w=9
	brick_h=4
	
	resetpills()
	
	levelnum = 1
	level = levels[levelnum]
	buildbricks(level)
	
	lives=3
	score=0
	multiplier=1
	pointsmult=1
	
	sticky=false
	sticky_x=flr(pad_w/2)

	-- reset powerups
	powerup=0
	powerup_t=0
	
	-- check where this is called
	-- remove if necessary if it works in here
	serveball()
	
end
	
function nextlevel()
	mode="game"
	
	pad_x=52
	pad_y=120
	pad_dx=0
	
	levelnum += 1
	if levelnum > #levels then
		--beaten the game, change
		-- gameover to special screen
		startgame()
	end
	level = levels[levelnum]
	buildbricks(level)
	
	sticky=false
	
	serveball()
end
	
	
function buildbricks(lvl)
	local i
	bricks={}
	
	j=0
	-- b = normal
	-- x = space
	-- i = indestructible
	-- h = hardened
	-- s = sploding
	-- p = powerup
	for i=1,#lvl do
		j+=1
		char=sub(lvl,i,i)
		
		if char=="b" 
		or char=="i" 
		or char=="h" 
		or char=="s" 
		or char=="p" then
			last=char
			addbrick(j,char)
		elseif char=="x" then
			last="x"
		elseif char=="/" then
			j=(flr((j-1)/11)+1)*11
		elseif char>="0" and char<="9" then
			for o=1,char+0 do
				if last=="b" 
				or last=="i" 
				or last=="h" 
				or last=="s" 
				or last=="p" then
					addbrick(j,last)
				elseif last=="x" then
					--nothing, empty space
				end
				j+=1
			end
			j-=1
		end
	end
end

function resetpills()
	pills={}
end
	
function addbrick(_i,_t)
	local _b = {}
	_b.x=4+((_i-1)%11)*(brick_w+2)
	_b.y=20+flr((_i-1)/11)*(brick_h+2)
	_b.v=true
	_b.t=_t
	add(bricks,_b)
end
	
function gameover()
	sfx(2)
	mode="gameover"
end

function levelover()
	sfx(8) -- todo change sound
	mode="levelover"
end

function levelfinished()
	if #bricks == 0 then return true end
	
	for i=1,#bricks do
		if bricks[i].v == true and bricks[i].t != "i" then
			return false
		end
	end
	return true
end
	
function serveball()
	ball={}
	ball[1] = newball()
	
	ball[1].x=pad_x+flr(pad_w/2)
	ball[1].y=pad_y-ball_r-pad_h
	ball[1].dx=1
	ball[1].dy=-1
	ball[1].ang=1
	ball[1].stuck=true
	pointsmult=1
	
	resetpills()
	
	sticky_x=flr(pad_w/2)
	
	-- reset powerups
	powerup=0
	powerup_t=0
end
	
function newball()
	b = {}
	b.x = pad_x+flr(pad_w/2)
	b.y = pad_y-ball_r-pad_h
	b.dx = 1
	b.dy = -1
	b.ang = 1
	b.stuck = false
	return b
end

function copyball(ob)
	b = {}
	b.x = ob.x
	b.y = ob.y
	b.dx = ob.dx
	b.dy = ob.dy
	b.ang = ob.ang
	b.stuck = ob.stuck
	return b
end	
	
function setang(bl, ang)
	--0.5
	--1.30 angle transform values
	bl.ang=ang
	if ang==2 then
		bl.dx=0.5*sign(bl.dx)
		bl.dy=1.3*sign(bl.dy)
	elseif ang==0 then
		bl.dx=1.3*sign(bl.dx)
		bl.dy=0.5*sign(bl.dy)	
	else
		bl.dx=1*sign(bl.dx)
		bl.dy=1*sign(bl.dy)
	end
end
	
function multiball()
	ball2 = copyball(ball[1])	
	ball3 = copyball(ball2)
	
	if ball[1].ang == 0 then
		setang(ball2, 1)
		setang(ball3, 2)
	elseif ball[1].ang == 1 then
		setang(ball2, 0)
		setang(ball3, 2)
	else
		setang(ball2, 0)
		setang(ball3, 1)
	end
	
	ball[#ball+1] = ball2
	ball[#ball+1] = ball3
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
		pointstuck(-1)
	end
	if btn(1) then
		-- right
		pad_dx=pad_speed
		buttpress=true
		pointstuck(1)
	end
	-- launch ball with x
	if btnp(5) then
		releasestuck()
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

// box and box collision
function box_box(box1_x,box1_y,box1_w,box1_h,box2_x,box2_y,box2_w,box2_h)
	if box1_y > box2_y+box2_h then	return false end
	if box1_y+box1_h < box2_y then	return false end
	if box1_x > box2_x+box2_w then	return false end
	if box1_x+box1_x < box2_x then	return false end
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
0000000006777760067777600677776006777760f677776f06777760067777600000000000000000000000000000000000000000000000000000000000000000
00000000559944955576777555b33bb555c1c1c55508800555e222e5558288850000000000000000000000000000000000000000000000000000000000000000
00700700559499955576777555b3bbb555cc1cc55508080555e222e5558288850000000000000000000000000000000000000000000000000000000000000000
00077000559949955576777555b3bbb555cc1cc55508800555e2e2e5558228850000000000000000000000000000000000000000000000000000000000000000
00077000554499955576677555b33bb555c1c1c55508080555e2e2e5558228850000000000000000000000000000000000000000000000000000000000000000
00700700059999500577775005bbbb5005cccc50f500005f05eeee50058888500000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000143501434014340143301333012320123101d3000d300203001e3001c3001a30019300183001630014300143001820019200192001a2001b2001b2001c2001c2001c2001c2001c2001c2001c20025700
000100002405024050240502405024050240402404024040240400f0001c0001f0001e000140000e0000c00019000200001f000200000d0000c0002700020000210002a0000c0000e0002a000210002100000000
000f00002d030290302603023030000002903026030220301f0300000025030220301f0301d030000000f0300c0300d0300d0300d0300d0300000000000000000000000000000000000000000000000000000000
0002000026450214501a45014450114500e4500b45008450074500545004450044500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000965008650086500765006650066500665022600236002560026600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300003b35039350383502635015350013500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000393503835036350343502f350313503a35000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000193501a3501d3500d3500f350223502435026350283500e3500f35011350123502a3502d3502e35025300000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000001c3501d3501f3502235023350193101c3202a3502c3502d35018320203502435027350293502c3502d3502e3502e3502e3500000000000000000000000000000000000000000000000000000000
000300003a4503a4503b4503640036400114000000000000197000000000000000000000000000000000000020600000000000037400000000000000000000000000000000000000000000000000000000000000
000200001c7501c7501d7501d75000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000166501a6501d6501f65020650206501f6501c6501965016650126500e65015000100000f0002d6002c6002b6002a600286002560023600206001e6001c60019600176001560013600106000d6000a600
00010000350502e050210501a050170503205034050310501d0501805017050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
