--[[pod_format="raw",created="2026-01-22 10:29:44",modified="2026-02-25 10:46:54",revision=32]]
function generateLeaves(arg)
	local iterations =  arg.iterations or 1
	local leafMinSize = arg.leafMinSize or arg.leafMaxSize or arg.leafSize or 1
	local leafMaxSize = arg.leafMaxSize or leafMinSize
	local kernelX = arg.kernelSizeX or arg.kernelSize or 1
	local kernelY = arg.kernelSizeY or kernelX
	local halfKernelX = kernelX//2
	local halfKernelY = kernelY//2
	
	local positionRandom = arg.positionRandom or halfKernelX
	
	local windAngle = arg.angle or arg.windAngle or 0
	local angleRandom = arg.angleRandom or 1
	
	local foregroundPercent = arg.foregroundPercent or 0
	
	srand(t())
	
	local i,x,y
	local leaves = {}
	local numForeground,numBackground = 0,0
	for i=1,iterations do
		for y=0,269,kernelY do
			for x=0,479,kernelX do
				local col = pget(x+halfKernelX,y+halfKernelY)  
				
				if (col>0) then
					local leaf = {}
					
					if (leafMaxSize == leafMinSize) then
						leaf.size = leafMaxSize
					else
						leaf.size = rnd(leafMaxSize - leafMinSize) + leafMinSize
					end
					
					leaf.x = x + halfKernelX + ((rnd(2) - 1) * positionRandom)
					leaf.y = y + halfKernelY + ((rnd(2) - 1) * positionRandom)
					
					local angle = windAngle + (rnd(angleRandom) - (angleRandom / 2))
					leaf.angle = angle
					--leaf.dx = cos(angle)
					--leaf.dy = sin(angle)
					
					leaf.color = col
					
					local fg = 0
					if (rnd() < foregroundPercent and col > 1) or (rnd(3) < foregroundPercent) then
						fg = 1
						numForeground += 1
					else
						numBackground += 1
					end
					
					leaf.foreground = fg
					leaf.variation = flr(rnd(3))
					
					add(leaves,leaf)
				end 
			end
		end
	end
	return leaves,numForeground,numBackground
end