local gameobjects = require("./gameobjects")
local force = {
	x = 0,
	y = 0,
}
force.__index = force
function force:Default()
	local f = {}
	setmetatable(f, force)
	return f
end

local function computeAppliedForce(target, objects)
	for object, force in pairs(forces) do
		if object == target then
			goto continue
		end
		::continue::
	end
	return forces[target]
end
local function applyForceToObject(object, oldForce, newForce)
	local dist = gameObjects.getDistance(enemy1, enemy2)
	local scaleFactor = math.log(1 / dist)
	--local scaleFactor = 1
	scaleFactor = math.min(scaleFactor, 3)
	-- todo: need to only adjust the forces if the given dimension (x or y) actually connects
	-- another idea: calculate vector towards enemy2 and move opposite to that
	local directionVector = gameObjects.getDirectionVector(enemy1, enemy2)
	forces[enemy1].y = forces[enemy1].y + directionVector.y * scaleFactor -- bounce back
	forces[enemy1].x = forces[enemy1].x + directionVector.x * scaleFactor -- bounce back
	-- bounce the second enemy forward
	forces[enemy2].y = forces[enemy2].y - directionVector.y * scaleFactor
	forces[enemy2].x = forces[enemy2].x - directionVector.x * scaleFactor
end

computeAppliedForce()
