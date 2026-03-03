function generate(arg)
	local iterations         = arg.iterations or 1
	local leaf_min_size      = arg.leaf_min_size or arg.leaf_max_size or arg.leaf_size or 1
	local leaf_max_size      = arg.leaf_max_size or leaf_min_size
	local kernel_x           = arg.kernel_size_x or arg.kernelSize or 1
	local kernel_y           = arg.kernel_size_y or kernel_x
	local half_kernel_x      = kernel_x //2
	local half_kernel_y      = kernel_y //2

	local position_random    = arg.position_random or half_kernel_x

	local wind_angle         = arg.angle or arg.wind_angle or 0
	local angle_random       = arg.angle_random or 1

	local foreground_percent = arg.foreground_percent or 0

	srand(t())

	local i, x, y
	local leaves = {}
	local num_foreground, num_background = 0, 0
	for i = 1, iterations do
		for y = 0, 269, kernel_y do
			for x = 0, 479, kernel_x do
				local col = pget(x + half_kernel_x, y + half_kernel_y)

				if (col > 0) then
					local leaf = {}

					if (leaf_max_size == leaf_min_size) then
						leaf.size = leaf_max_size
					else
						leaf.size = rnd(leaf_max_size - leaf_min_size) + leaf_min_size
					end

					leaf.x = x + half_kernel_x + ((rnd(2) - 1) * position_random)
					leaf.y = y + half_kernel_y + ((rnd(2) - 1) * position_random)

					local angle = wind_angle + (rnd(angle_random) - (angle_random / 2))
					leaf.angle = angle
					--leaf.dx = cos(angle)
					--leaf.dy = sin(angle)

					leaf.color = col

					local fg = 0
					if (rnd() < foreground_percent and col > 1) or (rnd(3) < foreground_percent) then
						fg = 1
						num_foreground += 1
					else
						num_background += 1
					end

					leaf.foreground = fg
					leaf.variation = flr(rnd(3))

					add(leaves, leaf)
				end
			end
		end
	end
	return leaves, num_foreground, num_background
end

function generate_leaves()
	cls()
	spr(4, 0, 0)
	leaf_table, foreground_leaves, background_leaves = generate { kernel_size_x = 2,
		kernel_size_y = 1.75,
		leaf_size = 1, iterations = 1,
		position_random = 6,
		wind_angle = 0.1,
		angle_random = 0.125,
		foreground_percent = 0.6 }
	leaf_data = userdata("i16", 5, #leaf_table)
	for index, leaf in pairs(leaf_table) do
		local sprite = 17 + ((leaf.color - 1) * 9) + (leaf.variation * 3)
		leaf_data:set(0, index - 1,
			sprite,
			(leaf.x - 3) * screen_to_i16,
			(leaf.y + 3) * screen_to_i16,
			leaf.angle * i16MAX,
			leaf.foreground * 10)
	end
	leaf_data:sort(4)
	store("assets/leafdata.pod", pod(leaf_data, 0x13, { fgLeaves = foreground_leaves, bgLeaves = background_leaves }))
	leaves = leaf_data:copy()
	spr(8, 0, 0)
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
		1, 0,              --src x,y
		0, 0,              --dst x,y
		1,                 --width
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
		1, 0,        --src x,y
		0, 0,        --dst x,y
		1,           --width
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

	local leaf_cursor_displace_x = cursor_effect_sample:take(leaf_cursor_ids)
	local leaf_cursor_displace_y = leaf_cursor_displace_x:copy()


	leaf_cursor_displace_x:mul(cursor.dx, true)
	leaf_cursor_displace_y:mul(cursor.dy, true)

	leaf_dx = userdata("f64", 1, leaf_data:height())
	leaf_dy = userdata("f64", 1, leaf_data:height())

	leaf_data:blit(leaves,
		0, 0,            --src x,y
		0, 0,            --dst x,y
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
		0, 0,     --src,dst offset
		1,        --length
		1,        --src stride
		leaves:width(), --dst stride
		leaves:height())

	leaves:add(leaf_dx, true,
		0, 1,     --src,dst offset
		1,        --length
		1,        --src stride
		leaves:width(), --dst stride
		leaves:height())
	leaves:add(leaf_dy, true,
		0, 2,     --src,dst offset
		1,        --length
		1,        --src stride
		leaves:width(), --dst stride
		leaves:height())
end
