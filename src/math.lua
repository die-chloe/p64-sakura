ud_sin = userdata("f64",128)

for i=0,127 do
	ud_sin[i] = sin(i/512)
end

ud_cos = userdata("f64",128)

for i=0,127 do
	ud_cos[i] = sin(i/512)
end