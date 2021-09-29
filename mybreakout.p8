pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-----------------------------
----------- main ------------
-----------------------------

// goals
// 6. juiciness (particles/shake)
// 	screen shake
//  text blinking
// 8. high score

function _init()
 cartdata("lazydevs_hero1")
	cls()	
	
	// state
	message=""	
	mode="start"
	level="xxxxxb"
	levelnum = 1
	levels={}
	--levels[1]="xxxxxb"
	--levels[2]="bxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbx"
	--levels[1]="i9b//x4b//sbsbsbsbsbsb"
	--levels[1]="i9b/p9pp9p/p9pp9p"
	levels[1]="////x4b/s9s"
 --levels[2]="b9b/p9p/sxsxsxsxsx/xbxbxbxbxbx"

	shake=0
	
	blink_g=7
	blink_i=1
	
	blink_w=7
	blink_w_i=1
	
	blink_b=7
	blink_b_i=1
	
	blink_f=0
	blink_s=8
	
	startcountdown=-1
	govercountdown=-1
	
	fadeperc=1
	
	arrm=1
	arrm2=1
	arrm_f=0
	
	--particles
	part={}
	
	lasthitx=0
	lasthity=0
	
	--highscore
	hs={}
	hs1={}
	hs2={}
	hs3={}
	reseths() --for some reason need to reset first in our implementation
	loadhs()
	addhs(450,2,2,2)
 hschars={"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"} 
	hs_x=128
	hs_dx=128
	loghs=false
	
	--typing in initials
	nitials={1,1,1}
	nit_sel=1
	nit_conf=false
	
	--debug
	debug1=""
end

--------------------------------
---- user defined functions ----
--------------------------------
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
		timer_slow = 900
	elseif _p==2 then
		-- life
		lives+=1
	elseif _p==3 then
	 -- catch
	 -- check if there are stuck balls
	 local hasstuck=false
	 for i=1,#ball do
	 	if ball[i].stuck then
	 		hasstuck=true
	 	end
	 end
	 if hasstuck==false then
	 	sticky=true
	 end
	elseif _p==4 then
		-- expand
		timer_expand = 900
		timer_reduce = 0
	elseif _p==5 then
		-- reduce
		timer_reduce = 900
		timer_expand = 0
	elseif _p==6 then
		-- megaball
		timer_mega=300
	elseif _p==7 then
		-- multiball
		multiball()
	end
end

-- todo fix indestructible b
function hitbrick(_i,_combo)
	local fshtime=8
	-- standard brick
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
		--spawn particles
		shatterbrick(bricks[_i],lasthitx,lasthity)
		bricks[_i].fsh=fshtime
	-- invincible brick
	elseif bricks[_i].t == "i" then
		sfx(9)
	-- hardened brick
	elseif bricks[_i].t == "h" then
		--if powerup==6 then
		if timer_mega > 0 then
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
	-- powerup brick
	elseif bricks[_i].t == "p" then
		sfx(7)
		if _combo then
			score+=multiplier*pointsmult
			multiplier+=1
		end
		bricks[_i].v=false
		spawnpill(bricks[_i].x,bricks[_i].y)
		--spawn particles
		shatterbrick(bricks[_i],lasthitx,lasthity)
		bricks[_i].fsh=fshtime
	-- sploding brick
	elseif bricks[_i].t == "s" then
		--splode sfx (pink?)
		sfx(11)
				shatterbrick(bricks[_i],lasthitx,lasthity)
		bricks[_i].t="zz"
		if _combo then
			score+=multiplier*pointsmult
			multiplier+=1
		end
		--spawn particles
		shatterbrick(bricks[_i],lasthitx,lasthity)
	end
end

function spawnpill(_x,_y)
	-- 7 because 7 powerups
	local _t
	local _pill
	_t =	flr(rnd(7)+1)
	-- for testing only
	--_t =	flr(rnd(2))
	--if _t == 0 then
		--_t = 3
	--else
	 --_t = 7
	--end
 -- for testing only
 
 _pill={}
 _pill.x=_x
 _pill.y=_y
 _pill.t=_t
 add(pills,_pill)
end

function checkexplosions()
	for i=1,#bricks do
		if bricks[i].t == "zz" and bricks[i].v then
			bricks[i].t = "z"
		end
	end

	for i=1,#bricks do
		if bricks[i].t == "z" and bricks[i].v then
			explodebrick(i)
			spawnexplosion(bricks[i].x,bricks[i].y)
			if shake < 0.5 then
				shake+=0.1
			end
			--if shake>0.5 then
			--	shake=1
			--end
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
	for j=1,#bricks do
		if j!=_i and bricks[j].v 
		and abs(bricks[j].x-bricks[_i].x) <= (brick_w+2)
		and abs(bricks[j].y-bricks[_i].y) <= (brick_h+2)
		then
			hitbrick(j, false)
			--shake+=0.4
			--if shake>1 then
				--shake = 1
			--end
		end
	end
	--shake+=0.4
	--if shake>1 then
		--shake = 1
	--end
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
	
	lives=0
	score=0
	multiplier=1
	pointsmult=1
	
	sticky=false
	sticky_x=flr(pad_w/2)
	
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
		-- error. game about to load
		-- a level that does not exist
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
	_b.fsh=0
	_b.ox=0
	_b.oy=-(128+rnd(128))
	_b.dx=0
	_b.dy=rnd(64)
	
	add(bricks,_b)
end
	
function gameover()
	sfx(2)
	mode="gameoverwait"
	govercountdown=60
	blink_s=16
end

function levelover()
	mode="wait"
	govercountdown=60
	blink_s=16
end

function wingame()
	mode="winnerwait"
	govercountdown=60
	blink_s=16
	
	-- determine score high enough
	printh("\n\nchecking score")
	printh(score)
	printh(hs[5])
	if score>hs[5] then
		loghs=true
	else
		loghs=true
		-- set above to false
	end
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
	
	-- powerup timers
	timer_slow=0
	timer_expand=0
	timer_reduce=0
	timer_mega=0
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
 local	ballnum = flr(rnd(#ball))+1
	local ogball = ball[ballnum]

	ball2 = copyball(ogball)	
 --	ball3 = copyball(ball2)
	
	if ogball.ang == 0 then
		--setang(ball2, 1)
		setang(ball2, 2)
	elseif ogball.ang == 1 then
		setang(ogball, 0)
		setang(ball2, 2)
		--setang(ball3, 2)
	else
		setang(ball2, 0)
		--setang(ball3, 1)
	end
	
	ball2.stuck=false
	ball[#ball+1] = ball2
	--ball[#ball+1] = ball3
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
-->8
-----------------------------
-------- juicy stuff --------
-----------------------------
function doshake()
	-- -16 to +16
	local shakex=16-rnd(32)
	local shakey=16-rnd(32)
	
	shakex=shakex*shake
	shakey=shakey*shake
	
	camera(shakex,shakey)
	
	shake*=0.95
	if shake<0.05 then
		shake=0
	end
end

function doblink()
	local g_seq={3,11,7,11}
	local w_seq={5,6,7,6}
	local b_seq={9,10,7,10}
	
	-- text blink
	blink_f+=1
	if blink_f > blink_s then
		blink_f = 0
		blink_i+=1
		if blink_i > #g_seq then
			blink_i=1
		end
		blink_g=g_seq[blink_i]
		
		blink_w_i+=1
		if blink_w_i > #w_seq then
			blink_w_i=1
		end
		blink_w=w_seq[blink_w_i]
		
		blink_b_i+=1
		if blink_b_i > #b_seq then
			blink_b_i=1
		end
		blink_b=b_seq[blink_b_i]
	end
	
	-- trajectory preview animation
	arrm_f+=1
	if arrm_f>30 then
		arrm_f=0
	end
	arrm=1+(2.5*(arrm_f/30))
	-- todo make method for dots??
	-- second dot
	local af2=arrm_f+15
	if af2>30 then
		af2-=30
	end
	arrm2=1+(2.5*(af2/30))
end

function fadepal(_perc)
 -- 0 means normal
 -- 1 is completely black
 
 local p=flr(mid(0,_perc,1)*100)
 
 local kmax,col,dpal,j,k
 
 dpal={0,1,1, 2,1,13,6,
          4,4,9,3, 13,1,13,14}
 
 -- now we go trough all colors
 for j=1,15 do
  --grab the current color
  col = j
  
  --now calculate how many
  --times we want to fade the
  --color.
  kmax=(p+(j*1.46))/22

  for k=1,kmax do
   col=dpal[col]
  end
  
  --finally, we change the
  --palette
  pal(j,col,1)
 end
end

--particle stuff

-- add a particle
function addpart(_x,_y,_dx,_dy,_type,_maxage,_col,_s)
 local _p={}
	_p.x=_x
	_p.y=_y
	_p.dx=_dx
	_p.dy=_dy
	_p.type=_type
	_p.maxage=_maxage
--	_p.col=0
	
	_p.colarr=_col
	_p.age=0
	_p.rot=0
	_p.rottimer=0
	_p.s=_s
	_p.os=_s
	
	add(part,_p) 
end

-- spawn a small puft of smoke
function spawnpuft(_x,_y)
	-- todo spawn puft on invincible brick hit?
	for i=0,5 do
		local _ang = rnd()
		local _dx = sin(_ang)*1
		local _dy = cos(_ang)*1
		addpart(_x,_y,_dx,_dy,2,15+rnd(15),{7,6,5},1+rnd(2))
	end
end

-- spawn a puft in the color of a pill
function spawnpillpuft(_x,_y,_p)
	-- todo spawn puft on invincible brick hit?
	for i=0,20 do
		local _ang = rnd()
		local _dx = sin(_ang)*(1+rnd(2))
		local _dy = cos(_ang)*(1+rnd(2))
		local _mycol
		if _p==1 then
			-- slow down -- orange
			timer_slow = 900
			_mycol = {9,9,4,4,0}
		elseif _p==2 then
			-- life -- white
			_mycol = {7,7,6,5,0}
		elseif _p==3 then
		 -- catch -- green
		 _mycol = {11,11,3,3,0}
		elseif _p==4 then
			-- expand -- blue
			_mycol = {12,12,13,5,0}
		elseif _p==5 then
			-- reduce -- black
			_mycol = {0,0,5,5,6}
		elseif _p==6 then
			-- megaball -- pink
			_mycol = {14,14,13,2,0}
		elseif _p==7 then
			-- multiball -- red
			_mycol = {8,8,4,2,0}
		end
		addpart(_x,_y,_dx,_dy,2,20+rnd(15),_mycol,1+rnd(4))
	end
end

-- spawn death particles
function spawndeath(_x,_y)
	-- todo spawn puft on invincible brick hit?
	for i=0,30 do
		local _ang = rnd()
		local _dx = sin(_ang)*(2+rnd(4))
		local _dy = cos(_ang)*(2+rnd(4))
		local _mycol
		
		_mycol = {10,10,10,10,9}
		
		addpart(_x,_y,_dx,_dy,2,20+rnd(15),_mycol,1+rnd(4))
	end
end

-- spawn explosion particles
function spawnexplosion(_x,_y)
 -- first smoke
	for i=0,20 do
		local _ang = rnd()
		local _dx = sin(_ang)*(rnd(4))
		local _dy = cos(_ang)*(rnd(4))
		local _mycol
		_mycol={0,0,5,5,6}
		addpart(_x,_y,_dx,_dy,2,80+rnd(15),_mycol,1+rnd(4))
	end
	--fireball
	for i=0,30 do
		local _ang = rnd()
		local _dx = sin(_ang)*(1+rnd(3))
		local _dy = cos(_ang)*(1+rnd(3))
		local _mycol
		_mycol={7,10,9,8,5}
		addpart(_x,_y,_dx,_dy,2,30+rnd(15),_mycol,1+rnd(4))
	end
end

-- spawn a trail particle
function spawntrail(_x,_y)
	if rnd()<0.5 then
		local _ang = rnd()
		local _dx = sin(_ang)*ball_r*0.5
		local _dy = cos(_ang)*ball_r*0.5
		
		addpart(_x+_dx,_y+_dy,0,0,0,15+rnd(15),{10,9})
	end
end

-- spawn mega trail particle
function spawnmtrail(_x,_y)
	if rnd()<0.5 then
		local _ang = rnd()
		local _dx = sin(_ang)*ball_r
		local _dy = cos(_ang)*ball_r
		
		addpart(_x+_dx,_y+_dy,0,0,2,60+rnd(15),{14,13,2},1.5+rnd(1))
	end
end

-- shatter brick
function shatterbrick(_b,_vx,_vy)
	-- bump the brick
	-- screenshake and sound
	if shake<0.5 then
		shake += 0.07
	end
	sfx(14)
	_b.ox+=_vx*1.1
	_b.oy+=_vy*1.1
	for x=0,brick_w do
		for y=0,brick_h do
			if rnd()<0.5 then
				local _ang = rnd()
				local _dx = sin(_ang)*rnd(2)+(_vx/2)
				local _dy = cos(_ang)*rnd(2)+(_vy/2)
				addpart(_b.x+x,_b.y+y,_dx,_dy,1,100,{7,6,5})
			end
		end
	end
	
	local chunks=1+flr(rnd(10))
	if chunks>0 then
		for i=0,chunks do
				local _ang = rnd()
	   local _dx = sin(_ang)*rnd(2)+(_vx/2)
	   local _dy = cos(_ang)*rnd(2)+(_vy/2)	
	   local _spr = 16+flr(rnd(14))
   	addpart(_b.x,_b.y,_dx,_dy,3,100,{_spr},0)
		end
	end
end

-- particle types
-- type 0 - static pixel
-- type 1 - gravity pixel
-- type 2 - ball of smoke
-- type 3 - rotating sprite

-- update particles
function updateparts()
	local _p
	for i=#part,1,-1 do
		_p=part[i]
		_p.age+=1
		if _p.age >= _p.maxage then
			del(part,part[i])
		-- doesn't work; want particles to disappear when offscreen
		elseif _p.x < -20 or _p.x > 148 then
			del(part,part[i])
		elseif _p.y < -20 or _p.y > 148 then
			del(part,part[i])
		else
			-- change colors
			if #_p.colarr==1 then
				_p.col=_p.colarr[1]
			else
				local _ci=(_p.age/_p.maxage)
				_ci=1+flr(_ci*#_p.colarr)
				_p.col = _p.colarr[_ci]
			end
			--if () > 0.5 then
				--_p.col=_p.oldcol
			--end
			
			-- apply gravity
			if _p.type==1 or _p.type==3 then
				_p.dy+=0.05
			end

			-- rotate sprite
			if _p.type==3 then
				_p.rottimer+=1
				if _p.rottimer>5 then
					_p.rot+=1
					_p.rottimer=0
					if _p.rot>=4 then
						_p.rot=0
					end
				end
			end
					
			-- shrink
			if _p.type == 2 then
				local _ci=1-(_p.age/_p.maxage)
				_p.s=_ci*_p.os
			end
		
			-- friction
			if _p.type == 2 then
				_p.dx=_p.dx/1.2
				_p.dy=_p.dy/1.2
			end			
			
			-- move particle
			_p.x+=_p.dx
			_p.y+=_p.dy
		end
	end
end

-- draw particles
function drawparts()
	local _p
	for i=1,#part do
		_p=part[i]
		if _p.type==0 or _p.type==1 then
			pset(_p.x,_p.y,_p.col)
		elseif _p.type==2 then
			circfill(_p.x,_p.y,_p.s,_p.col)
		elseif _p.type==3 then
			local _fx,_fy
			--type 3 => sprite
			if _p.rot==1 then
				_fx=false
				_fy=false
			elseif _p.rot==2 then
				_fx=false
				_fy=true
			elseif _p.rot==3 then
				_fx=true
				_fy=true
			elseif _p.rot==4 then
				_fx=true
				_fy=false
			else
				_fx=false
				_fy=false
			end
			spr(_p.col,_p.x,_p.y,1,1,_fx,_fy)
		end
	end
end

-- rebound bricks
function animatebricks()
	for i=1,#bricks do
		local _b=bricks[i]
		if _b.v or _b.fsh>0 then
			-- see if brick is moving
		 if _b.dx!=0 or _b.dy!=0 or _b.ox!=0 or _b.oy!=0 then
			 --moves brick depending on speed
				_b.ox+=_b.dx
				_b.oy+=_b.dy
				--changes brick speed
				_b.dx-=_b.ox/15
				_b.dy-=_b.oy/15
				--if speed of brick soon to be 0, slow down
				if abs(_b.dx) > _b.ox then
					_b.dx=_b.dx/1.3
				end
				if abs(_b.dy) > _b.oy then
					_b.dy=_b.dy/1.3
				end
				--if close to 0, stop
				if abs(_b.ox) < 0.2 and abs(_b.dx)<0.2 then
					_b.dx=0
					_b.ox=0
				end
				if abs(_b.oy) < 0.2 and abs(_b.dy)<0.2 then
					_b.dy=0
					_b.oy=0
				end
			end
		end 
	end
end
-->8
-----------------------------
-------- update func --------
-----------------------------

function _update60()
	doblink()
	doshake()
	updateparts()
	if mode=="game" then
		update_game()
	elseif mode=="start" then
		update_start()
	elseif mode=="gameover" then
		update_gameover()
	elseif mode=="gameoverwait" then
		update_gameoverwait()
	elseif mode=="levelover" then
		update_levelover()
	elseif mode=="leveloverwait" then
		update_leveloverwait()
	elseif mode=="winner" then
		update_winner()
	elseif mode=="winnerwait" then
		update_winnerwait()
	end
end

function update_start()
	-- slide the high score list
	if hs_x!=hs_dx then
		hs_x+=(hs_dx-hs_x)/5
	end
	
	if startcountdown < 0 then
	
		-- fade in game
		if fadeperc!=0 then
			fadeperc-=0.05
			if fadeperc<0 then
				fadeperc=0
			end
		end

		if btn(5) then
			startcountdown=80
			blink_s=1
			sfx(13)
			--startgame()
		end
		if btnp(0) then
			hs_dx=0
		end
		if btnp(1) then
			hs_dx=128
		end
	else
		startcountdown-=1
		fadeperc=(80-startcountdown)/80
		doblink()
		if startcountdown<=0 then
			startcountdown=-1
			blink_s=8
		--	fadeperc=0
			startgame()
			hs_x=128
			hs_dx=0
		end
	end
end

function update_gameover()
 if	govercountdown<0 then
		if btn(5) then
			govercountdown=80
			blink_s=1
			sfx(13)
		end
	else
		govercountdown-=1
		fadeperc=(80-govercountdown)/80
		doblink()
		if govercountdown<=0 then
			govercountdown=-1
			blink_s=8
			--fadeperc=0
			startgame()
		end
	end
end

function update_gameoverwait()
	govercountdown-=1
	if govercountdown<=0 then
		govercountdown=-1
  mode="gameover"
	end
end

function update_winnerwait()
	govercountdown-=1
	if govercountdown<=0 then
		govercountdown=-1
		blink_s=4
  mode="winner"
  sfx(8)
	end
end

function update_winner()
 if	govercountdown<0 then
 	-- initials selection buttons
 	if loghs then
 	 if btnp(0) then
 	 	--left
 	 	nit_sel-=1
 	 	if nit_sel<1 then
 	 		nit_sel=3
 	 	end
 		end
 		if btnp(1) then
 			--right
 			nit_conf=false
 			nit_sel+=1
 			if nit_sel>3 then
 				nit_sel=1
 			end
 		end
 		if btnp(2) then
 			--up
 			nit_conf=false
 			nitials[nit_sel]-=1
 			if nitials[nit_sel]<1 then
 				nitials[nit_sel]=#hschars
 			end
 		end
 		if btnp(3) then
 			--down
 			nit_conf=false
 			nitials[nit_sel]+=1
 			if nitials[nit_sel]>#hschars then
 				nitials[nit_sel]=1
 			end
 		end
 		if btnp(5) then
 			--x, confirm initials
 			if nit_conf then
 				--addhs(points/score,nitials[1],nitials[2],nitials[3])
					--savehs()
	 			govercountdown=80
					blink_s=1
					sfx(15)
				else
				 nit_conf=true
				end
 		end
 		if btnp(4) then
 			if nit_conf then
 			 nit_conf=false
 			 --sfx
 			end
 		end
 		
 	else
			if btn(5) then
				govercountdown=80
				blink_s=1
				sfx(15)
			end
		end
	else
		govercountdown-=1
		fadeperc=(80-govercountdown)/80
		doblink()
		if govercountdown<=0 then
			govercountdown=-1
			blink_s=8
			--fadeperc=0
			mode="start"
		end
	end
end

function update_leveloverwait()
	govercountdown-=1
	if govercountdown<=0 then
		govercountdown=-1
  mode="levelover"
  sfx(8)
	end
end

function update_levelover()
 if	govercountdown<0 then
		if btn(5) then
			govercountdown=80
			blink_s=1
			sfx(15)
		end
	else
		govercountdown-=1
		fadeperc=(80-govercountdown)/80
		doblink()
		if govercountdown<=0 then
			govercountdown=-1
			blink_s=8
			--fadeperc=0
			nextlevel()
		end
	end
end

function update_game()
	local nextx,nexty,brickhit

	-- fade in game
	if fadeperc!=0 then
		fadeperc-=0.05
		if fadeperc<0 then
			fadeperc=0
		end
	end

	-- check if pad should grow/shrink
	if timer_expand > 0 then
		-- todo gradual growth
		pad_w=flr(pad_wo*1.5)
	elseif timer_reduce > 0 then
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
			spawnpillpuft(pills[i].x,pills[i].y,pills[i].t)
			-- remove pill
			del(pills,pills[i])
			sfx(12)
		end
	end
	
	checkexplosions()

	-- powerup timers
	if timer_slow > 0 then
		timer_slow-=1
	end
	if timer_expand > 0 then
		timer_expand-=1
	end
	if timer_reduce > 0 then
		timer_reduce-=1
	end
	if timer_mega > 0 then
		timer_mega-=1
	end	
	
	-- animate bricks
 animatebricks()
end

function updateball(b)
	
	if b.stuck then
		--ball_x=pad_x+flr(pad_w/2)
		-- only sticky for first ball for now
	 b.x=pad_x+sticky_x
		b.y=pad_y-ball_r-1
	else
		--regular ball physics
		if timer_slow > 0 then
			nextx=b.x+(b.dx/2)
			nexty=b.y+(b.dy/2)
		else
			nextx=b.x+b.dx
			nexty=b.y+b.dy
		end
		
		-- check if ball hit pad	
		if ball_box(nextx,nexty,pad_x,pad_y,pad_w,pad_h) then
			shake+=0.01
			spawnpuft(nextx,nexty)
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
					if (timer_mega <= 0) 
					or (timer_mega > 0 and bricks[i].t=="i") then 
						lasthitx=b.dx
			  	lasthity=b.dy
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
			if levelnum >= #levels then
				wingame()
			else
				levelover()
			end
		end
		
		-- move ball
		b.x=nextx
		b.y=nexty
		
		-- spawn trail
		if timer_mega > 0 then
			spawnmtrail(b.x,b.y)
		else
			spawntrail(b.x,b.y)
		end
		
		-- this is where we check
		--- if the ball hits the edges
		if nextx > 127 or nextx < 0 then
			nextx=mid(0,nextx,127)
			b.dx=-b.dx
			sfx(0)
			spawnpuft(nextx,nexty)
		end
		if nexty < (banner+2) then
			nexty=mid(0,nexty,127)
			b.dy=-b.dy
			sfx(0)
			spawnpuft(nextx,nexty)
		elseif nexty > 129 then
			-- ball is lost
			sfx(3)
			spawndeath(b.x,b.y)
			if #ball > 1 then
				shake+=0.15
				del(ball,b)
			else
				shake+=0.4
				lives-=1
				if lives < 0 then
					gameover()
				else
					serveball()
				end
			end
		end
		
	end -- end of sticky if
end
-->8
-----------------------------
-------- drawin func --------
-----------------------------

function _draw()
	if mode=="game" then
		draw_game()
	elseif mode=="start" then
		draw_start()
	elseif mode=="gameover" then
		draw_gameover()
	elseif mode=="gameoverwait" then
  draw_game()
	elseif mode=="levelover" then
		draw_levelover()
	elseif mode=="leveloverwait" then
		draw_game()
	elseif mode=="winner" then
		draw_winner()
	elseif mode=="winnerwait" then
		draw_game()
	end

	--fade the screen
	pal()
	if fadeperc != 0 then
		fadepal(fadeperc)
	end
end

function draw_game()
	-- fill background
	cls()
	--cls(1)
	rectfill(0,0,127,127,1)
	
	rectfill(pad_x,pad_y,pad_x+pad_w,pad_y+pad_h,7)
	
	-- draw bricks
	for i=1,#bricks do
		local _b = bricks[i]
		if _b.v or _b.fsh>0 then
			if _b.fsh>0 then
				brickcol=7
				_b.fsh-=1
			elseif _b.t == "b" then
				brickcol = 14
			elseif _b.t == "i" then
				brickcol = 15
			elseif _b.t == "h" then
				brickcol = 6
			elseif _b.t == "s" then
				brickcol = 8
			elseif _b.t == "p" then
				brickcol = 12
			--this type for debug only
			elseif _b.t == "z" or _b.t == "zz" then
				brickcol = 3
			end
			local _bx = _b.x+_b.ox
			local _by = _b.y+_b.oy
			rectfill(_bx,_by,_bx+brick_w,_by+brick_h,brickcol)
		end
	end
	
	-- particles
	drawparts()
	
	-- draw pills
	for i=1,#pills do
		if pills[i].t==5 then
			palt(0,false)
			palt(15,true)
		end
		spr(pills[i].t,pills[i].x,pills[i].y)
		palt()
	end
	
		-- draw ball and paddle
	print(message, 0, 0, 8)
	for i=1,#ball do
			local ballc=ball_color
			if timer_mega > 0 then
				--ballc = 14
			end
			circfill(ball[i].x,ball[i].y,ball_r,ballc)
			if ball[i].stuck then
--				line(ball[i].x+ball[i].dx*4*arrm,
--				ball[i].y+ball[i].dy*4*arrm,
--				ball[i].x+ball[i].dx*6*arrm,
--				ball[i].y+ball[i].dy*6*arrm,
--				10)
				-- trajectory preview dots
				pset(ball[i].x+ball[i].dx*4*arrm,
					ball[i].y+ball[i].dy*4*arrm,
					10)
				pset(ball[i].x+ball[i].dx*4*arrm2,
					ball[i].y+ball[i].dy*4*arrm2,
					10)
			end
	end

	-- ui
	rectfill(0,0,128,banner,0)
	if debug1!="" then
		print("debug:"..debug1,1,1,7)
	else
		print("lives:"..lives,1,1,7)
		print("score:"..score,40,1,7)
	print("debug:"..debug1,80,1,7)
	end
end

function draw_start()
	cls()
	prinths(hs_x)
	print("pico hero breakout",30+(hs_x-128),30,7)
	print("press ❎ to start",32,80,blink_g)
	print("press ⬅️ for hi-scores",22,90,3)
end

function draw_gameover()
	rectfill(0,60,128,75,0)
	print("game over!",47,62,7)
	print("press ❎ to restart",30,68,blink_w)
end

function draw_levelover()
	rectfill(0,60,128,75,0)
	print("stage clear!",47,62,7)
	print("press ❎ to continue",30,68,blink_w)
end

function draw_winner()
	if loghs then
		--won, type name for score
		local _y=30
		rectfill(0,_y,128,_y+52,12)
		print("★★congratulations!★★",17,_y+4,1)
		print("you have beaten the game!",15,_y+14,7)
		print("enter your initials for",18,_y+20,7)
		print("the high score list",28,_y+26,7)
		local _colors = {7,7,7}
		if nit_conf then
			_colors = {10,10,10}
		else
			_colors[nit_sel] = blink_b
		end
		
		print(hschars[nitials[1]],57,_y+35,_colors[1])
		print(hschars[nitials[2]],61,_y+35,_colors[2])
		print(hschars[nitials[3]],65,_y+35,_colors[3])
		--print("aaa",57,_y+35,blink_w)
		if nit_conf then
			print("press ❎ to confirm",29,_y+44,blink_b)
		else
			print("use ⬅️➡️⬆️⬇️❎",34,_y+44,6)
		end
	else		
		-- won but no high score
		local _y=30
		rectfill(0,_y,128,_y+52,12)
		print("★ congratulations! ★",22,_y+4,1)
		print("you have beaten the game!",15,_y+14,7)
		print("but you did not achieve",18,_y+20,7)
		print("a high score",38,_y+26,7)
		print("try again?",42,_y+32,7)
		print("press ❎ for main menu",22,_y+44,blink_b)
	end
end

-->8
-----------------------------
-------- high score ---------
-----------------------------

-- resets the high score list
function reseths()
	hs={10,300,400,200,1000}
	hs1={1,1,8,1,1}
	hs2={2,5,1,9,15}
	hs3={1,2,5,21,1}
	
	sorths()
	savehs()
	--dget(0)
end

-- add a new high score
function addhs(_score,_c1,_c2,_c3)
	add(hs,_score)
	add(hs1,_c1)
	add(hs2,_c2)
	add(hs3,_c3)
	sorths()
end

-- sort high score
function sorths()
 for i=1,#hs do
  local j = i
  while j > 1 and hs[j-1] < hs[j] do
   hs[j],hs[j-1]=hs[j-1],hs[j]
   hs1[j],hs1[j-1]=hs1[j-1],hs1[j]
   hs2[j],hs2[j-1]=hs2[j-1],hs2[j]
   hs3[j],hs3[j-1]=hs3[j-1],hs3[j]
   j = j - 1
  end
 end
end

-- load the high score
function loadhs()
	local _slot=0
	if dget(0)==1 then	
		-- load the data
		_slot+=1
		for i=1,5 do
		 printh("\n\nprinting slots")
		 printh(dget(_slot))
		 printh(dget(_slot+1))
		 printh(dget(_slot+2))
		 printh(dget(_slot+3))
			hs[i]=dget(_slot)
			hs1[i]=dget(_slot+1)
			hs2[i]=dget(_slot+2)
			hs3[i]=dget(_slot+3)
			_slot+=4
		end
		sorths()
	else
		reseths()
	end
end

function savehs()
	local _slot
	dset(0,1)
	-- save the data
	_slot=1
	for i=1,5 do
		dset(_slot, hs[i])
		dset(_slot+1, hs1[i])
		dset(_slot+2, hs2[i])
		dset(_slot+3, hs3[i])
		_slot+=4
	end
end

--print the high score
function prinths(_x)
	rectfill(_x+30,4,_x+99,12,8)
	print("high scores",_x+45,6,7)
	for i=1,5 do
		-- player rank
		print(i.." - ",_x+30,10+7*i,5)
		
		local _c=7
		if i==1 then
		 _c=blink_w
		end
		
  local _name
  _name = hschars[hs1[i]]
  printh("\n\n new logs")
  printh("hs1[i] "..hs1[i])
  printh(_name)
  _name = _name..hschars[hs2[i]]
  _name = _name..hschars[hs3[i]]
		--print(hs[i]..hs2[i]..hs3[i],_x+45,10+7*i,7)
		print(_name,_x+45,10+7*i,_c)
		
		-- player score
		local _score=" "..hs[i]
		print(_score,(_x+100)-(#_score*4),10+7*i,_c)
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000070000000000077700000000000007000000000000000000000000000000
00070000000070000007000000000000000000000000000000000000000000000000770000000000007700000000000007700000000000000000000000000000
00777000000077000077700000070000007000000000000000000700000777000000770007777000007000000007000000700000000000700000000000000000
00770000000070000077700000077000007700000770000000077700000070000070777007007000000000000007000000000000000000770000000000000000
00000000000000000000000000000000007700000000000000000000000077000777700000000000000000000777000000000000000007700000000000000000
00000000000000000000000000000000000000000000000000000000000000000777000000000000000000000000000000000000000007000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000143501434014340143301333012320123101d3000d300203001e3001c3001a30019300183001630014300143001820019200192001a2001b2001b2001c2001c2001c2001c2001c2001c2001c20025700
000100002405024050240502405024050240402404024040240400f0001c0001f0001e000140000e0000c00019000200001f000200000d0000c0002700020000210002a0000c0000e0002a000210002100000000
000f00002d030290302603023030000002903026030220301f0300000025030220301f0301d030000000f0300c0300d0300d0300d0300d0300000000000000000000000000000000000000000000000000000000
0002000026450214501a45014450114500e4500b45008450074500545004450044500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000965008650086500765006650066500665022600236002560026600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300003b35039350383502635015350013500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000393503835036350343502f350313503a35000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000193501a3501d3500d3500f350223502435026350283500e3500f35011350123502a3502d3502e35025300000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000001c3501d3501f3502235023350193101c3202a3502c3502d35018320203502435027350293502c3502d3502e3502e3502e3500000000000000000000000000000000000000000000000000000000
0003000023450264502b4502e45032450114000000000000197000000000000000000000000000000000000020600000000000037400000000000000000000000000000000000000000000000000000000000000
000200001c7501c7501d7501d75000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000016670126700f6700e6700c6700b6700b6700a6700a6700967009670096700867008670086700767007670076700667006670066700667006670066500665006640076300562008610086100861007610
00010000350502e050210501a050170503205034050310501d0501805017050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000405013050050501d05007050240600c0602c050120403104017030350301c030380301f0303b030240303e0202400026000000000000000000000000000000000000000000000000000000000000000
000400003f6502e6501b6501765015630106200e6300c6200c6200a620096200b4000c40011400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000040500b050050500e05007050110600c06016050120401d04017030230301c030260301f0302a030240302c030260302e04029040310402b030260002900023000229001d90020900000000000000000
0005000014f001af001ff0026f0029f002df002ff0031f0033f0034f0032f002df0028f0021f001df0017f0017f002af002ef002bf0027f0023f001ef0019f0018f001cf0023f0027f0022f001bf0014f0012f00
