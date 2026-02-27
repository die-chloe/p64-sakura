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
	spr(9, 0, 0)
	leaf_table, foreground_leaves, background_leaves = generate {kernel_size_x = 2,
		kernel_size_y = 1.75,
		leaf_size = 1, iterations = 1,
		position_random = 6,
		wind_angle = 0.1,
		angle_random = 0.125,
		foreground_percent = 0.6}
	leaf_data = userdata("i16", 5, #leaf_table)
	for index, leaf in pairs(leaf_table) do
		local sprite = 25 + ((leaf.color - 1) * 9) + (leaf.variation * 3)
		leaf_data:set(0, index - 1,
					  sprite,
					  (leaf.x - 3) * screen_to_i16,
					  (leaf.y + 3) * screen_to_i16,
					  leaf.angle * i16MAX,
					  leaf.foreground * 10)
	end
	leaf_data:sort(4)
	store("assets/leafdata.pod", pod(leaf_data, 0x13, {fgLeaves = foreground_leaves, bgLeaves = background_leaves}))
	leaves = leaf_data:copy()
	spr(8, 0, 0)
end

function generate_grass()
	cls()
	spr(10, 0, 0)
	grass_table = generate {kernel_size_x = 3, kernel_size_y = 2.5,
		position_random = 3}
	grass_data = userdata("i16", 5, #grass_table)
	for index, blade in pairs(grass_table) do
		grass_data:set(0, index - 1,
					   19,
					   (blade.x - 8) * screen_to_i16,
					   (blade.y - 14) * screen_to_i16,
					   false, false)
	end
	grass_data:sort(1, true)
	grass_data:sort(2, false)
	store("assets/grass_data.pod", pod(grass_data, 0x13))
end
