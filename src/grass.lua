function generate_grass()
    cls()
    spr(5, 0, 0)
    grass_table = generate { kernel_size_x = 3, kernel_size_y = 2.5,
        position_random = 3 }
    grass_data = userdata("i16", 5, #grass_table)
    for index, blade in pairs(grass_table) do
        grass_data:set(0, index - 1,
            11,
            (blade.x - 8) * screen_to_i16,
            (blade.y - 14) * screen_to_i16,
            false, false)
    end
    grass_data:sort(1, true)
    grass_data:sort(2, false)
    store("assets/grass_data.pod", pod(grass_data, 0x13))
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
        0,             --src offset
        0,             --dst offset
        1,             --length
        1,             --src stride
        grass_data:width(), --dst stride
        grass_data:height()) --num elements
end
