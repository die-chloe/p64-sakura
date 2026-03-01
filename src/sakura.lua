include "particles.lua"
include "cursor_effects.lua"

leaf_noise_strength        = 8
leaf_noise_sprite_strength = 2.5
grass_noise_strength       = 3
grass_noise_bias           = 2.5
noise_scale_leaves         = 4

noise_scale_grassx         = 1
noise_scale_grassy         = .5

frame                      = 0

i8MAX                      = 0x7f
i16MAX                     = 0x7fff
i32MAX                     = 0x7fffffff

screen_to_i16              = i16MAX / 480

--regen = true


function _init()
	init_noise()
	init_leaves()
	init_grass()

	add_particles(1, true)

	for i = 0, 60 do
		_update()
	end

	init_mouse()
end

grass_wind = 0

function _update()

	if (frame % 2) == 0 then
		noise_x -= 1
	end

	if (frame % 32) == 0 then
		noise_y += 1
	end

	noise_x %= noise_w
	noise_y %= noise_h

	noise:blit(noise_sample,
			   noise_x, noise_y, -- src x,y
			   0, 0,    -- dst x,y
			   noise_w, noise_h)
	update_particles()

	update_mouse()

	frame += 1
end

function _draw()
	cls()
	spr(1, 0, 0)


	update_leaves()
	update_grass()

	spr(leaves, 0, bg_leaves)

	draw_particles()

	spr(2, 0, 0)

	spr(leaves, bg_leaves * leaves:width(), fg_leaves)

	spr(grass)

	spr(3,0,190)

	draw_mouse()
end

function init_noise()
	noise_sample, noise_meta = unpod(fetch("assets/perlin1.pod"))
	noise_sample = noise_sample:convert("f64")

	if (noise_meta.format == "i8") then
		conversion = i8MAX
	elseif (noise_meta.format == "i16") then
		conversion = i16MAX
	elseif (noise_meta.format == "i32") then
		conversion = i32MAX
	else
		conversion = 1
	end

	noise_sample:mul(1 / conversion, true)

	noise_w, noise_h = noise_sample:width(), noise_sample:height()

	noise = userdata("f64", noise_w * 2, noise_h * 2)
	noise_sample:blit(noise, 0, 0, 0, 0)
	noise_sample:blit(noise, 0, 0, noise_w, 0)
	noise_sample:blit(noise, 0, 0, 0, noise_h)
	noise_sample:blit(noise, 0, 0, noise_w, noise_h)

	noise_x, noise_y = 0, 0
end

function init_leaves()
	leaf_data, leaf_meta = unpod(fetch("assets/leafdata.pod"))
	leaf_data = leaf_data:convert("f64")
	fg_leaves = leaf_meta.fgLeaves
	bg_leaves = leaf_meta.bgLeaves

	leaf_data:mul(1 / screen_to_i16, true,
				  1, --source offset
				  1, --dest offset
				  2, --length
				  leaf_data:width(),
				  leaf_data:width(),
				  leaf_data:height())

	local leaf_pos = userdata("f64", 2, leaf_data:height())
	local leaf_noise_pos = userdata("f64", 2, leaf_data:height())
	leaf_data:blit(leaf_pos,
				   1, 0, --src x,y
				   0, 0, --dst x,y
				   2, leaf_data:height())

	leaf_pos:mul(1 / noise_scale_leaves, leaf_noise_pos)

	leaf_pos = leaf_pos:convert("i32")
	leaf_noise_pos = leaf_noise_pos:convert("i32")
	leaf_noise_pos:mod(noise_w, true)

	leaf_vec = userdata("f64", 2, leaf_data:height())

	for i = 0, leaf_data:height() - 1 do
		local angle = leaf_data:get(3, i) / i16MAX

		leaf_vec:set(0, i,
					 cos(angle),
					 sin(angle))
	end

	leaf_noise_ids = userdata("i32", 1, leaf_noise_pos:height())
	local leaf_noise_idx = userdata("i32", 1, leaf_noise_pos:height())
	leaf_noise_pos:blit(leaf_noise_idx,
						0, 0, --src x,y
						0, 0, --dst x,y
						1,
						leaf_noise_pos:height())

	leaf_noise_pos:blit(leaf_noise_ids,
						1, 0,  --src x,y
						0, 0,  --dst x,y
						1,     --width
						leaf_noise_pos:height()) --height

	leaf_noise_ids:mul(noise_w, true)
	leaf_noise_ids:add(leaf_noise_idx, true)


	leaf_cursor_ids = userdata("i32", 1, leaf_noise_pos:height())
	local leaf_cursor_idx = userdata("i32", 1, leaf_noise_pos:height())


	leaf_pos:blit(leaf_cursor_idx,
				  0, 0, --src x,y
				  0, 0, --dst x,y
				  1,
				  leaf_pos:height())
	leaf_pos:blit(leaf_cursor_ids,
				  1, 0,  --src x,y
				  0, 0,  --dst x,y
				  1,     --width
				  leaf_pos:height()) --height

	leaf_cursor_ids:mul(480, true)
	leaf_cursor_ids:add(leaf_cursor_idx, true)

	leaves = userdata("f64", 3, leaf_data:height())
end

function update_leaves()
	local leaf_displace = noise_sample:take(leaf_noise_ids)

	leaf_sprite = leaf_displace:mul(leaf_noise_sprite_strength)
	leaf_sprite:max(-1, true)
	leaf_sprite:min(1, true)

	leaf_displace:mul(leaf_noise_strength, true)

	local leaf_cursor_displace_x = (cursor_effect_sample:take(leaf_cursor_ids))
	leaf_cursor_displace_x = leaf_cursor_displace_x:convert("f64")
	local leaf_cursor_displace_y = leaf_cursor_displace_x:copy()


	leaf_cursor_displace_x:mul(cursor.dx, true)
	leaf_cursor_displace_y:mul(cursor.dy, true)

	leaf_dx = userdata("f64", 1, leaf_data:height())
	leaf_dy = userdata("f64", 1, leaf_data:height())

	leaf_data:blit(leaves,
				   0, 0,      --src x,y
				   0, 0,      --dst x,y
				   3, leaf_data:height()) --width,height

	leaf_vec:blit(leaf_dx,
				  0, 0, --src x,y
				  0, 0, --dst x,y
				  1, leaf_vec:height())

	leaf_vec:blit(leaf_dy,
				  1, 0, --src x,y
				  0, 0, --dst x,y
				  1, leaf_vec:height())

	leaf_dx:mul(leaf_displace, true)
	leaf_dy:mul(leaf_displace, true)

	leaf_dx:add(leaf_cursor_displace_x, true)
	leaf_dy:add(leaf_cursor_displace_y, true)

	leaves:add(leaf_sprite, true,
			   0, 0,  --src,dst offset
			   1,     --length
			   1,     --src stride
			   leaves:width(), --dst stride
			   leaves:height())

	leaves:add(leaf_dx, true,
			   0, 1,  --src,dst offset
			   1,     --length
			   1,     --src stride
			   leaves:width(), --dst stride
			   leaves:height())
	leaves:add(leaf_dy, true,
			   0, 2,  --src,dst offset
			   1,     --length
			   1,     --src stride
			   leaves:width(), --dst stride
			   leaves:height())
end

function init_grass()
	grass_data = unpod(fetch("assets/grass_data.pod")):convert("f64")
	grass_data:mul(1 / screen_to_i16, true,
				   1, --source offset
				   1, --dest offset
				   2, --length
				   grass_data:width(),
				   grass_data:width(),
				   grass_data:height())

	grass = userdata("f64", 5, grass_data:height())
	grass = grass_data:copy()

	grass_noise_idx = userdata("f64", 1, grass_data:height())
	grass_noise_ids = userdata("f64", 1, grass_data:height())

	grass_data:blit(grass_noise_idx,
					1, 0, --src x,y
					0, 0,
					1,
					grass_data:height())
	grass_noise_idx:mul(1 / noise_scale_grassx, true)
	grass_noise_idx = grass_noise_idx:convert("i32")
	grass_noise_idx:mutate("i32", grass_data:height(), 1)
	grass_noise_idx:mod(noise_w, true)

	grass_data:blit(grass_noise_ids,
					2, 0, --src x,y
					0, 0,
					1,
					grass_data:height())
	grass_noise_ids:mul(1 / noise_scale_grassy, true)
	grass_noise_ids = grass_noise_ids:convert("i32")
	grass_noise_ids:mutate("i32", grass_data:height(), 1)
	grass_noise_ids:mod(noise_h, true)
	grass_noise_ids:mul(noise_w, true)

	grass_noise_ids:add(grass_noise_idx, true)
end

function update_grass()
	grass_delta = noise_sample:take(grass_noise_ids)
	grass_delta:mul(grass_noise_strength, true)
	grass_delta:add(grass_noise_bias, true)
	grass_delta:min(4, true)
	grass_delta:max(-3, true)

	grass_data:add(grass_delta, grass,
				   0,       --src offset
				   0,       --dst offset
				   1,       --length
				   1,       --src stride
				   grass_data:width(), --dst stride
				   grass_data:height()) --num elements
end
