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
	return player
end

function gameEntity:Enemy()
	local enemy = {}
	setmetatable(enemy, gameEntity)
	enemy["speed"] = 100
	enemy["health"] = 100
	enemy["x"] = 75
	enemy["y"] = 100
	return enemy
end

local gameProjectile = {
	radius = 10,
	speed = 200,
	x = nil,
	y = nil,
	damage = 20,
	size = 20,
	color = { 0.3, 0.3, 0.3 },
	collisions = 1,
}
gameProjectile.__index = gameProjectile
function gameProjectile:seekingProjectile(enemyId, x, y)
	local seekingProjectile = {}
	setmetatable(seekingProjectile, gameProjectile)
	seekingProjectile["enemyId"] = enemyId
	seekingProjectile["x"] = x
	seekingProjectile["y"] = y
	return seekingProjectile
end
function gameProjectile:default(x, y)
	local proj = {}
	setmetatable(proj, gameProjectile)
	proj["x"] = x
	proj["y"] = y
	return proj
end

exports["gameProjectile"] = gameProjectile
exports["gameEntity"] = gameEntity
return exports
