include "leaves.lua"
include "grass.lua"
include "particles.lua"
include "cursor_effects.lua"


leaf_noise_strength        = 8   --How many pixels one noise unit moves the leaf sprites
leaf_noise_sprite_strength = 2.5 --How much one noise unit shifts the sprite index

grass_noise_strength       = 3   --How much one noise unit shifts the sprite index
grass_noise_bias           = 2.5 --Which sprite index a noise value of 0 correlates to


--Scales the noise to element mapping also affects how fast the scroll moves
--Larger values: Larger waves but faster
--Smaller values: Smaller waves but slower
noise_scale_leaves = 4
noise_scale_grassx = 1
noise_scale_grassy = 0.5


frame       = 0
draw_grass  = true
draw_leaves = true


--Some constants for easier conversion
i8MAX         = 0x7f
i16MAX        = 0x7fff
i32MAX        = 0x7fffffff
screen_to_i16 = i16MAX / 480



--Debug
--[[
cpu     = 0
outline = "\f7\^o1ff"
--]]

function _init()
	--[[ 	if (regen) then
		generate_leaves()
		generate_grass()
		exit()
	end ]]

	init_noise()
	init_leaves()
	init_grass()

	add_particles(1, true)

	for i = 0, 120 do
		update_particles()
	end

	init_mouse()

	--Set up "frame buffers" for fast blitting to the screen during draw
	background = userdata("u8", 480, 270) --Static elements that never have to be redrawn
	draw_buffer = userdata("u8", 480, 270) --For leaves and grass that have to be redrawn every 2nd frame

	set_draw_target(background)
	spr(1)
	poke(0x5509, 0x7f) --Set the Write Mask to write 0x40 to the table selection for masking
	spr(2, 0, 0)
	poke(0x5509, 0x3f) --Reset Write Mask


	cpu_new = stat(1)
end

function _update()
	if (frame % 2) == 0 then
		noise_x -= 1

		update_leaves()
		draw_grass = true
	else
		update_grass()
		draw_leaves = true
	end

	if (frame % 32) == 0 then
		noise_y += 1
		cpu_max, cpu_min = 0, 1
	end

	noise_x %= noise_w
	noise_y %= noise_h

	noise:blit(noise_sample,
		noise_x, noise_y, -- src x,y
		0, 0,       -- dest x,y
		noise_w, noise_h)

	update_particles()

	update_mouse()

	frame += 1
end

function _draw()
	set_draw_target(draw_buffer)

	--Draw leaves if the last _update updated the grass and the other way around
	--If a draw misses an _update it draws both parts of the image at once
	--In which case the particles are drawn twice bc I could not figure out how
	--to draw the leaves and grass to the buffer w/o messing with the masking bits :c

	if (draw_leaves) then
		clip(0, 0, 480, 168)
		blit(background)

		poke(0x550a, 0x7f) --Set the Target Mask as to not draw in front of elements
		spr(leaves, 0, bg_leaves)
		draw_particles()
		poke(0x550a, 0x3f) --Reset the Target Mask

		spr(leaves, bg_leaves * leaves:width(), fg_leaves)
		draw_leaves = false
	end

	if (draw_grass) then
		clip(0, 168, 480, 102)
		blit(background)

		poke(0x550a, 0x7f) --Set the Target Mask as to not draw in front of elements
		draw_particles()
		poke(0x550a, 0x3f) --Reset the Target Mask

		spr(grass)

		spr(3, 0, 190)
		draw_grass = false
	end

	draw_mouse()


	clip()
	set_draw_target()
	blit(draw_buffer)


	--DIAGNOSTICS
	--[[
	cpu_old = cpu_new
	cpu_new = stat(1)
	cpu_max = max(cpu_max, cpu_new)
	cpu_min = min(cpu_min, cpu_new)
	cpu = (cpu_old + cpu_new) / 2


	print(outline .. string.format("CPU (average last 2 f): %.1f%%", cpu * 100), 4, 16)
	print(outline .. string.format("CPU (max/min last 32f): %.1f%%/%.1f%%", cpu_max * 100, cpu_min * 100))
	print(outline .. string.format("RAM: %.3fMB", stat(0) / 1000000))
	print(outline .. stat(7) .. "fps")
	--]]
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

	--Create a 4x larger userdata that the "sampling" window scrolls across so that 
	--the update can be done in a single blit
	noise = userdata("f64", noise_w * 2, noise_h * 2)
	noise_sample:blit(noise, 0, 0, 0, 0)
	noise_sample:blit(noise, 0, 0, noise_w, 0)
	noise_sample:blit(noise, 0, 0, 0, noise_h)
	noise_sample:blit(noise, 0, 0, noise_w, noise_h)

	noise_x, noise_y = 0, 0
end
