--[[pod_format="raw",created="2026-02-06 22:44:09",modified="2026-02-09 21:08:36",revision=1]]
ud_sin = userdata("f64",128)

for i=0,127 do
	ud_sin[i] = sin(i/512)
end

ud_cos = userdata("f64",128)

for i=0,127 do
	ud_cos[i] = sin(i/512)
end