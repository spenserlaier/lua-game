local exports = {}

local gameEntity = {
	x = 0,
	y = 0,
	size = 25,
	color = { 0.4, 0.4, 0.4 },
}
gameEntity.__index = gameEntity
function gameEntity:Player()
	local player = {}
	setmetatable(player, self)
	player["speed"] = 200
	player["health"] = 100
	player["x"] = 400
	player["y"] = 300
	player["collisionCooldownTime"] = 0
	return player
end

function gameEntity:Enemy()
	local enemy = {}
	setmetatable(enemy, gameEntity)
	enemy["speed"] = 500
	enemy["health"] = 100
	enemy["x"] = 75
	enemy["y"] = 100
	return enemy
end

local gameProjectile = {
	radius = 10,
	speed = 1000,
	x = nil,
	y = nil,
	damage = 20,
	size = 15,
	color = { 0.3, 0.3, 0.3 },
	collisions = 1,
	collisionCooldownTime = 0,
}
gameProjectile.__index = gameProjectile
function gameProjectile:SeekingProjectile(enemyId, x, y)
	local seekingProjectile = {}
	setmetatable(seekingProjectile, gameProjectile)
	seekingProjectile["enemyId"] = enemyId
	seekingProjectile["x"] = x
	seekingProjectile["y"] = y
	return seekingProjectile
end
function gameProjectile:Default(x, y, dirX, dirY)
	local proj = {}
	setmetatable(proj, gameProjectile)
	proj["x"] = x
	proj["y"] = y
	proj["dirX"] = dirX
	proj["dirY"] = dirY
	return proj
end
local function getDistance(obj1, obj2)
	local obj1CenterY = obj1.y
	local obj1CenterX = obj1.x
	local obj2CenterY = obj2.y
	local obj2CenterX = obj2.x

	if obj1.size ~= nil then
		obj1CenterX = obj1.x + obj1.size / 2
		obj1CenterY = obj1.y + obj1.size / 2
	end
	if obj2.size ~= nil then
		obj2CenterX = obj2.x + obj2.size / 2
		obj2CenterY = obj2.y + obj2.size / 2
	end
	local yDiff = obj1CenterY - obj2CenterY
	local xDiff = obj1CenterX - obj2CenterX
	local distance = math.sqrt((xDiff * xDiff + yDiff * yDiff))
	return distance
end

local function getClosestObjectToTarget(target, objects)
	local minDist = nil
	local minKey = nil
	for i, object in pairs(objects) do
		local dist = getDistance(target, object)
		if minDist == nil or dist < minDist then
			minDist = dist
			minKey = i
		end
	end
	return minKey
end

local function moveObjectTowardsTarget(object, target, dt)
	local yDiff = target.y - object.y
	local xDiff = target.x - object.x
	local vectorLength = getDistance(object, target)
	local unitX = xDiff / vectorLength
	local unitY = yDiff / vectorLength

	object.x = object.x + object.speed * dt * unitX
	object.y = object.y + object.speed * dt * unitY
end

local function cleanUpProjectiles(projectiles, screenWidth, screenHeight)
	for idx, projectile in pairs(projectiles) do
		local projCenterX = projectile.x + projectile.size / 2
		local projCenterY = projectile.y + projectile.size / 2
		if projCenterX < 0 or projCenterX >= screenWidth then
			projectiles[idx] = nil
		end
		if projCenterY < 0 or projCenterY >= screenHeight then
			projectiles[idx] = nil
		end
	end
end
local function getObjectCenter(object)
	return { x = object.x + (object.size / 2), y = object.y + (object.size / 2) }
end
local function getDirectionVector(object, target)
	local yDiff = target.y - object.y
	local xDiff = target.x - object.x
	local vectorLength = getDistance(object, target)
	local unitX = xDiff / vectorLength
	local unitY = yDiff / vectorLength
	return { x = unitX, y = unitY }
end

exports["gameProjectile"] = gameProjectile
exports["gameEntity"] = gameEntity
exports["getClosestObjectToTarget"] = getClosestObjectToTarget
exports["moveObjectTowardsTarget"] = moveObjectTowardsTarget
exports["cleanUpProjectiles"] = cleanUpProjectiles
exports["getDistance"] = getDistance
exports["getDirectionVector"] = getDirectionVector
return exports
