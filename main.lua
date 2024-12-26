-- Set up global variables or constants
local player = {
	x = 400,
	y = 300,
	speed = 200,
	size = 25,
	health = 100,
}

--local enemy = {
--	x = 100,
--	y = 100,
--	size = 30,
--}
local deadEnemyIds = {}
local playerProjectiles = {}
local isRunning = true -- Game state flag
local enemyId = 0

local function generateId()
	local id = 0.0
	return function()
		id = id + 1.0
		return id
	end
end
local getNextEnemyId = generateId()
local function copyTable(original)
	--TODO: experiment with metatables for more idiomatic inheritance/object oriented programming
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = value
	end
	return copy
end

local ballProjectileTemplate = {
	radius = 10,
	speed = 25,
	x = nil,
	y = nil,
	enemyId = nil, -- track the current enemy that the projectile is tracking?
	damage = 20,
	size = 20,
	color = { 0.3, 0.3, 0.3 },
}

local function generateBallProjectile(player, enemyId)
	local ball = copyTable(ballProjectileTemplate)
	ball.x = player.x
	ball.y = player.y
	ball.enemyId = enemyId
	return ball
end

local function detectCollision(obj1, obj2)
	return math.abs(obj1.x - obj2.x) < (obj1.size + obj2.size) / 2
		and math.abs(obj1.y - obj2.y) < (obj1.size + obj2.size) / 2
end

local function convertListToSet(list)
	local set = {}
	for i = 1, #list do
		set[list[i]] = true
	end
	return set
end

-- Load assets and initialize the game
function love.load()
	love.window.setTitle("Lua Survivors")
	love.graphics.setBackgroundColor(0.2, 0.3, 0.4)
end

local function drawPlayer()
	love.graphics.setColor(0.1, 0.8, 0.2)
	love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)
end

local function drawCircleFill(object)
	love.graphics.setColor(object.color[1], object.color[2], object.color[3])
	love.graphics.circle("fill", object.x, object.y, object.size)
end

local function getDistance(obj1, obj2)
	local yDiff = obj1.y - obj2.y
	local xDiff = obj1.x - obj2.x
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

local testEnemy = {
	x = 0,
	y = 0,
	speed = 25,
	color = { 0.5, 0.5, 0.5 },
	size = 25,
	health = 100,
}
local enemies = {}
enemies[getNextEnemyId()] = testEnemy
-- Update game logic (called every frame)
local movementKeysPressed = {}
function love.update(dt)
	if isRunning then
		-- Player movement
		for _, enemy in pairs(enemies) do
			moveObjectTowardsTarget(enemy, player, dt)
		end
		for i = 1, #playerProjectiles do
			local projectile = playerProjectiles[i]
			moveObjectTowardsTarget(projectile, enemies[projectile.enemyId], dt)
		end
		if movementKeysPressed["up"] then
			player.y = player.y - player.speed * dt
		end
		if movementKeysPressed["down"] then
			player.y = player.y + player.speed * dt
		end
		if movementKeysPressed["left"] then
			player.x = player.x - player.speed * dt
		end
		if movementKeysPressed["right"] then
			player.x = player.x + player.speed * dt
		end
	end
end

-- Draw graphics (called every frame)
function love.draw()
	if isRunning then
		-- Draw player
		drawPlayer()
		-- Draw enemy
		for _, enemy in pairs(enemies) do
			drawCircleFill(enemy)
		end
		for i = 1, #playerProjectiles do
			drawCircleFill(playerProjectiles[i])
		end
	else
		-- Game over screen
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Game Over! Press R to restart.", 300, 250, 0, 2, 2)
	end
end

-- Handle keypress events
local movementMappings = {
	up = { up = true, w = true },
	down = { down = true, s = true },
	left = { left = true, a = true },
	right = { right = true, d = true },
}
function love.keyreleased(key)
	if movementMappings.up[key] ~= nil then
		movementKeysPressed["up"] = false
	end
	if movementMappings.down[key] ~= nil then
		movementKeysPressed["down"] = false
	end
	if movementMappings.left[key] ~= nil then
		movementKeysPressed["left"] = false
	end
	if movementMappings.right[key] ~= nil then
		movementKeysPressed["right"] = false
	end
end
function love.keypressed(key)
	if key == "space" then
		local closestTarget = getClosestObjectToTarget(player, enemies)
		if closestTarget ~= nil then
			print("generating a ball projectile...")
			local ball = generateBallProjectile(player, closestTarget)
			print(ball)
			table.insert(playerProjectiles, ball)
		end
	end
	if movementMappings.up[key] ~= nil then
		if movementKeysPressed["down"] == true then
			movementKeysPressed["down"] = false
		end
		movementKeysPressed["up"] = true
	end
	if movementMappings.down[key] ~= nil then
		if movementKeysPressed["up"] == true then
			movementKeysPressed["up"] = false
		end
		movementKeysPressed["down"] = true
	end
	if movementMappings.right[key] ~= nil then
		if movementKeysPressed["left"] == true then
			movementKeysPressed["left"] = false
		end
		movementKeysPressed["right"] = true
	end
	if movementMappings.left[key] ~= nil then
		if movementKeysPressed["right"] == true then
			movementKeysPressed["right"] = false
		end
		movementKeysPressed["left"] = true
	end
	if not isRunning and key == "r" then
		-- Reset game
		player.x, player.y = 400, 300
		isRunning = true
	elseif key == "escape" then
		love.event.quit() -- Quit game
	end
end
