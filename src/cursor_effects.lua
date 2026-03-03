cursor = {x = 0, y = 0, dx = 0, dy = 0}

cursor_leaf_effect_strength = 1/32

cursor_effect = userdata("f64", 31, 31)
cursor_effect_sample = userdata("f64", 480, 270)
cursor_effect_max_speed = 8
cursor_effect_min_speed = 1.5
function init_mouse()
	cursor.x, cursor.y = mouse()
	for y = 0, 30 do
		for x = 0, 30 do
			local dx, dy = (x - 15), (y - 15)
			local dist = min(16,max(2,sqrt(dx * dx + dy * dy)))
			dist = ((16/dist) - 1) * 16
			cursor_effect:set(x, y, dist)
		end
	end
end

function update_mouse()
	new_mouse_x, new_mouse_y = mouse()

	cursor.dx = (new_mouse_x - cursor.x)
	cursor.dy = (new_mouse_y - cursor.y)

	local cursor_delta = vec(cursor.dx,cursor.dy):magnitude()
	local cursor_clamped_delta = min(cursor_effect_max_speed - cursor_effect_min_speed,max(0, cursor_delta - cursor_effect_min_speed)) * cursor_leaf_effect_strength

	cursor.dx = cursor_clamped_delta * (cursor.dx / cursor_delta)
	cursor.dy = cursor_clamped_delta * (cursor.dy / cursor_delta)


	
	
	cursor_effect_sample = userdata("f64", 480, 270)
	blit(cursor_effect, cursor_effect_sample,
		 0, 0,    --src x,y
		new_mouse_x - ((new_mouse_x - cursor.x)//2) - 15, --dst x
		new_mouse_y - ((new_mouse_y - cursor.y)//2) - 15) --dst y

	cursor.x, cursor.y = new_mouse_x, new_mouse_y
end

function draw_mouse()
	--cursor_effect_sample = userdata("u8", 480, 270)
	--blit(cursor_effect_sample)
end
