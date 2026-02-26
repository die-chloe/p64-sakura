--[[pod_format="raw",created="2026-02-25 12:52:31",modified="2026-02-26 22:15:44",revision=218]]
max_particles = 128
--num_particles = 0

particle_gravity = 0.325
particle_wind = 0.085
particle_wind_noise = 0.325
particle_drag = 0.625
particle_spr_effect = 4

noise_scale_particles = 4

function update_particles()
	if(rnd()<0.085) add_particles(flr(rnd(2)) + 1)
	
	local p_idx = userdata("f64",1,particles:height())
	local p_ids = userdata("f64",1,particles:height())
	
	particles:blit(p_idx,
						1,0,
						0,0,
						1)
	particles:blit(p_ids,
						2,0,
						0,0,
						1)
	
	p_idx:mul(1/noise_scale_particles,true)
	p_idx = p_idx:convert("i32")	
	p_idx:mod(noise_w,true)
	
	p_ids:mul(1/noise_scale_particles,true)
	p_ids = p_ids:convert("i32")
	p_ids:mod(noise_h,true)
	p_ids:mul(noise_w,true)
	p_ids:add(p_idx,true)
	
	p_dx = noise_sample:take(p_ids)
	
	p_spr_eff = p_dx:mul(particle_spr_effect)
	p_spr_eff:max(-1,true)
	p_spr_eff:min(1,true)
	p_spr_eff:add(0.5,true)
	
	p_dx:mul(particle_wind_noise,true)
	p_dx:add(particle_wind,true)
	
	particles:mul(particle_drag,true,
					0,
					3,
					1,
					0,
					particles:width(),
					particles:height())
	
	particles:add(p_dx,true,
					0, --src offset
					3, --dest offset
					1, --length
					1, --src stride
					particles:width(), --dest stride
					particles:height()) --spans
	
	particles:add(particles,true,
					3, --src offset
					1, --dest offset
					1, --length
					particles:width(), --src stride
					particles:width(), --dest stride
					particles:height())--spans
	
	particles:add(particle_gravity,true,
					0, --src offset
					2, --dst offset
					1, --length
					0, --src stride
					particles:width(), --dest stride
					particles:height()) --spans
end

function draw_particles()
	blit(p_sprites,particles,
		0,0,
		0,0,
		1,
		particles:height())
	particles:add(p_spr_eff,true,
				0,
				0,
				1,
				1,
				particles:width(),
				particles:height())
	spr(particles,0,particles:height(),3)
end

function add_particles(amount,init)
	if(amount<1) return
	local p_ids = userdata("i32",amount)
	local new_particles,new_p_sprites
	for i=0,amount do
		p_ids:set(i,rnd(leaves:height()))
	end
	p_ids:mul(leaf_data:width(),true)
	
	if (init) then
		new_particles = userdata("f64",4,amount)
		new_p_sprites = userdata("f64",1,amount)
	else
		new_particles = userdata("f64",4,min(particles:height()+ amount,max_particles))
		new_p_sprites = userdata("f64",1,new_particles:height())
		particles:blit(new_particles,
							0,0,			--src x,y
							0,amount)	--dst x,y
		p_sprites:blit(new_p_sprites,
							0,0,
							0,amount)
	end
	
	leaf_data:take(p_ids,new_particles,
						0,		--id offset
						0,		--dest offset
						3,		--span length
						1,		--id stride
						new_particles:width(),	--dest stride
						amount) --spans
	new_particles:blit(new_p_sprites,
						0,0,
						0,0,
						1,
						amount)
	particles = new_particles:copy()
	p_sprites = new_p_sprites:copy()
end