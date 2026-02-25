--[[pod_format="raw",created="2026-01-22 10:20:50",modified="2026-02-25 13:01:45",revision=1093]]
include "math.lua"
include "genLeaves.lua"
include "particles.lua"

leaf_noise_strength = 8
leaf_noise_sprite_strength = 2.5
grass_noise_strength = 3
grass_noise_bias = 2.5
noise_scale_leaves = 4
noise_scale_grassx = 1
noise_scale_grassy = .5

max_particles = 1000
num_particles = 0

frame = 0

i8MAX = 0x7f
i16MAX = 0x7fff
i32MAX = 0x7fffffff

screen_to_i16 = i16MAX/480

--regen = true


function _init()
	cls()
	spr(8,0,0)
	
	if not regen then
		leaf_data,leaf_meta = unpod(fetch("assets/leafdata.pod"))
		leaf_data = leaf_data:convert("f64")
		fg_leaves = leaf_meta.fgLeaves
		bg_leaves = leaf_meta.bgLeaves
		
		grass_data = unpod(fetch("assets/grass_data.pod")):convert("f64")
		grass_data:mul(1/screen_to_i16,true,
						1, --source offset
						1, --dest offset
						2, --length
						grass_data:width(),
						grass_data:width(),
						grass_data:height())
		
		grass = userdata("f64",5,grass_data:height())
		grass = grass_data:copy()
		
		noise_sample,noise_meta = unpod(fetch("assets/perlin1.pod"))
		noise_sample = noise_sample:convert("f64")
		
		if(noise_meta.format == "i8") then conversion = i8MAX
		elseif(noise_meta.format == "i16") then conversion = i16MAX
		elseif(noise_meta.format == "i32") then conversion = i32MAX
		else conversion = 1 end
		
		noise_sample:mul(1/conversion,true)
		
		noise_w,noise_h = noise_sample:width(),noise_sample:height()
		
		noise = userdata("f64",noise_w*2,noise_h*2)
		noise_sample:blit(noise,0,0,	0,			0)
		noise_sample:blit(noise,0,0,	noise_w,	0)
		noise_sample:blit(noise,0,0,	0,			noise_h)
		noise_sample:blit(noise,0,0,	noise_w,	noise_h)
		
		noise_x,noise_y = 0,16
		
		
		leaf_data:mul(1/screen_to_i16,true,
						1, --source offset
						1, --dest offset
						2, --length
						leaf_data:width(),
						leaf_data:width(),
						leaf_data:height())
		
		leaf_pos = userdata("f64",2,leaf_data:height())
		leaf_data:blit(leaf_pos,
							1,0, --src x,y
							0,0, --dst x,y
							2,leaf_data:height())
							
		leaf_pos:mul(1/noise_scale_leaves,true)
		
		leaf_pos = leaf_pos:convert("i32")
		leaf_pos:mod(noise_w,true)
		
		leaf_vec = userdata("f64",2,leaf_data:height())
		
		for i=0,leaf_data:height()-1 do
			local angle =leaf_data:get(3,i)/i16MAX
			
			leaf_vec:set(0,i,
							cos(angle),
							sin(angle))
		end
		
		leaf_noise_ids = userdata("i32",1,leaf_pos:height())
		leaf_noise_idx = userdata("i32",1,leaf_pos:height())
		leaf_pos:blit(leaf_noise_idx,
							0,0, --src x,y
							0,0, --dst x,y
							1,
							leaf_pos:height())
		leaf_noise_idx:mutate("i32",leaf_pos:height(),1)
		leaf_pos:blit(leaf_noise_ids,
							1,0, --src x,y
							0,0, --dst x,y
							1, --width
							leaf_pos:height()) --height
		leaf_noise_ids:mutate("i32",leaf_pos:height(),1)
		leaf_noise_ids:mul(noise_w,true)
		leaf_noise_ids:add(leaf_noise_idx,true)
						
		leaves = userdata("f64",3,leaf_data:height())
		
		grass_noise_idx = userdata("f64",1,grass_data:height())
		grass_noise_ids = userdata("f64",1,grass_data:height())
		
		
		
		grass_data:blit(grass_noise_idx,
							1,0, --src x,y
							0,0,
							1,
							grass_data:height())
		grass_noise_idx:mul(1/noise_scale_grassx,true)
		grass_noise_idx = grass_noise_idx:convert("i32")
		grass_noise_idx:mutate("i32",grass_data:height(),1)
		--grass_noise_idx:add(8,true)
		grass_noise_idx:mod(noise_w,true)
		
		
		grass_data:blit(grass_noise_ids,
							2,0, --src x,y
							0,0,
							1,
							grass_data:height())
		grass_noise_ids:mul(1/noise_scale_grassy,true)
		grass_noise_ids = grass_noise_ids:convert("i32")
		grass_noise_ids:mutate("i32",grass_data:height(),1)
		--\grass_noise_ids:add(14,true)
		grass_noise_ids:mod(noise_h,true)
		grass_noise_ids:mul(noise_w,true)
		
		
		grass_noise_ids:add(grass_noise_idx,true)
		
	end
end

function generate()
	cls()
	spr(9,0,0)
	leafTable,foregroundLeaves,backgroundLeaves = generateLeaves{kernelSizeX=2,
																kernelSizeY=1.9,
																leafSize=1,iterations=1,
																positionRandom=6,
																windAngle=0.1,
																angleRandom=0.125,
																foregroundPercent = 0.5}
	leaf_data = userdata("i16",5,#leafTable)
	for index,leaf in pairs(leafTable) do
		local sprite = 25 + ((leaf.color - 1) * 9) + (leaf.variation * 3)
		leaf_data:set(0,index-1,
							sprite,
							(leaf.x-3) * screen_to_i16,
							(leaf.y+3) * screen_to_i16,
							leaf.angle * i16MAX,
							leaf.foreground * 10)
	end
	leaf_data:sort(4)
	store("assets/leafdata.pod",pod(leaf_data,0x13,{fgLeaves=foregroundLeaves,bgLeaves=backgroundLeaves}))
	leaves = leaf_data:copy()
	spr(8,0,0)
end

function generateGrass()
	cls()
	spr(10,0,0)
	grassTable = generateLeaves{kernelSizeX=3,kernelSizeY=1.75,
										positionRandom = 3}
	grass_data = userdata("i16",5,#grassTable)
	for index,blade in pairs(grassTable) do
		grass_data:set(0,index-1,
							19,
							(blade.x - 8) * screen_to_i16,
							(blade.y - 14) * screen_to_i16,
							false,false)
		store("assets/grass_data.pod",pod(grass_data,0x13))
	end
end

grass_wind = 0

function _update()
	if(regen) then
		generate()
		generateGrass()
		exit()
	end
	
	if(frame%2) == 0 then
		noise_x -= 1
	end
	
	if (frame%32) == 0 then
		noise_y += 1
	end
	
	noise_x %= noise_w
	noise_y %= noise_h
	
	noise:blit(noise_sample,
				noise_x,noise_y, -- src x,y
				0,0, -- dst x,y
				noise_w,noise_h)
	
	
	leaf_displace = noise_sample:take(leaf_noise_ids)
	
	leaf_sprite = leaf_displace:mul(leaf_noise_sprite_strength)
	leaf_sprite:max(-1,true)
	leaf_sprite:min(1,true)
	
	leaf_displace:mul(leaf_noise_strength,true)
	
	leaf_dx = userdata("f64",1,leaf_data:height())
	leaf_dy = userdata("f64",1,leaf_data:height())
	
	leaf_data:blit(leaves,
					0,0, --src x,y
					0,0, --dst x,y
					3,leaf_data:height()) --width,height
	
	leaf_vec:blit(leaf_dx,
						0,0, --src x,y
						0,0, --dst x,y
						1,leaf_vec:height())
						
	leaf_vec:blit(leaf_dy,
						1,0, --src x,y
						0,0, --dst x,y
						1,leaf_vec:height())
						
	leaf_dx:mul(leaf_displace,true)
	leaf_dy:mul(leaf_displace,true)
	
	leaves:add(leaf_sprite,true,
					0,0, --src,dst offset
					1, --length
					1, --src stride
					leaves:width(), --dst stride
					leaves:height())
	
	leaves:add(leaf_dx,true,
					0,1, --src,dst offset
					1,--length
					1, --src stride
					leaves:width(), --dst stride
					leaves:height())
	leaves:add(leaf_dy,true,
					0,2, --src,dst offset
					1,--length
					1, --src stride
					leaves:width(), --dst stride
					leaves:height())
	
	grass_delta = noise_sample:take(grass_noise_ids)
	grass_delta:mul(grass_noise_strength,true)
	grass_delta:add(grass_noise_bias,true)
	grass_delta:min(4,true)
	grass_delta:max(-3,true)
	
	grass_data:add(grass_delta,grass,
						0, --src offset
						0, --dst offset
						1, --length
						1, --src stride
						grass_data:width(), --dst stride
						grass_data:height()) --num elements
	
	frame += 1
end

function _draw()
	cls()
	spr(8,0,0)
	
	
	spr(leaves,0,bg_leaves)
	
	spr(11,0,0)
	
	spr(leaves,bg_leaves*leaves:width(),fg_leaves)
	
	spr(grass)
	
	print(stat(1),4,4,7)
	print(string.format("%.3fMB",stat(0)/1000000))
	print(stat(7).."fps")
end