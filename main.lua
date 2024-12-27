local gameObjects = require("./gameobjects")
-- Set up global variables or constants
local gameEntity = gameObjects["gameEntity"]
local gameProjectile = gameObjects["gameProjectile"]
local player = gameEntity:Player()
local playerProjectiles = {}
local isRunning = true -- Game state flag
local SCREEN_WIDTH = 800
local SCREEN_HEIGHT = 600
local MAP_WIDTH = 10000
local MAP_HEIGHT = 10000
local success = love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)
local enemySpawnInterval = 1
local timeUntilNextEnemy = 1
local enemySpawnRadius = 1
local maxEnemies = 15
local enemies = {}
local numEnemies = 0

local function generateId()
	local id = 0.0
	return function()
		id = id + 1.0
		return id
	end
end

local function generateEnemyAroundPlayer(player, radius, angleRadian)
	local offsetX = (radius * math.cos(angleRadian))
	local offsetY = (radius * math.sin(angleRadian))
	local enemy = gameEntity:Enemy()
	enemy.x = player.x + offsetX
	enemy.y = player.y + offsetY
	if 0 <= enemy.x and enemy.x < MAP_WIDTH and 0 <= enemy.y and enemy.y < MAP_HEIGHT then
		return enemy
	end
	return nil
end

local function generateRandomEnemy(player, radius)
	local enemy = nil
	while enemy == nil do
		local randomRadian = math.random(0, 2 * math.pi)
		enemy = generateEnemyAroundPlayer(player, radius, randomRadian)
	end
	return enemy
end

local getNextEnemyId = generateId()

local function detectCollision(obj1, obj2)
	return math.abs(obj1.x - obj2.x) < (obj1.size + obj2.size) / 2
		and math.abs(obj1.y - obj2.y) < (obj1.size + obj2.size) / 2
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

local function sprayRingProjectiles(player, numProjectiles)
	local angleInterval = (2 * math.pi) / numProjectiles
	local currentAngle = 0
	for i = 1, numProjectiles do
		local xOffset = (1 * math.cos(currentAngle))
		local yOffset = (1 * math.sin(currentAngle))
		currentAngle = currentAngle + angleInterval
		table.insert(
			playerProjectiles,
			gameProjectile:Default(player.x + player.size / 2, player.y + player.size / 2, xOffset, yOffset)
		)
	end
end
local testEnemy = gameEntity:Enemy()
enemies[getNextEnemyId()] = testEnemy
-- Update game logic (called every frame)
local movementKeysPressed = {}
function love.update(dt)
	if isRunning then
		if numEnemies < maxEnemies and timeUntilNextEnemy <= 0 then
			table.insert(enemies, generateRandomEnemy(player, 100))
			numEnemies = numEnemies + 1
			timeUntilNextEnemy = enemySpawnInterval
		end
		for p_key, projectile in pairs(playerProjectiles) do
			-- TODO: determine whether to have projectile only collide with target,
			-- or allow collision with any target
			for e_key, enemy in pairs(enemies) do
				if detectCollision(projectile, enemy) then
					enemy.health = enemy.health - projectile.damage
					if enemy.health <= 0 then
						enemies[e_key] = nil
						numEnemies = numEnemies - 1
					end
					projectile.collisions = projectile.collisions - 1
					if projectile.collisions == 0 then
						playerProjectiles[p_key] = nil
					end
				end
			end
		end
		timeUntilNextEnemy = timeUntilNextEnemy - dt
		gameObjects.cleanUpProjectiles(playerProjectiles, SCREEN_WIDTH, SCREEN_HEIGHT)
		for _, enemy in pairs(enemies) do
			gameObjects.moveObjectTowardsTarget(enemy, player, dt)
		end
		for _, projectile in pairs(playerProjectiles) do
			if projectile.enemyId ~= nil then
				gameObjects.moveObjectTowardsTarget(projectile, enemies[projectile.enemyId], dt)
			elseif projectile.dirX ~= nil and projectile.dirY ~= nil then
				gameObjects.moveObjectTowardsTarget(
					projectile,
					{ x = projectile.x + projectile.dirX, y = projectile.y + projectile.dirY },
					dt
				)
			end
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
		for _, projectile in pairs(playerProjectiles) do
			drawCircleFill(projectile)
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
		sprayRingProjectiles(player, 12)
		local closestTarget = gameObjects.getClosestObjectToTarget(player, enemies)
		--if closestTarget ~= nil then
		if false then
			--TODO

			--local ball = generateBallProjectile(player, closestTarget)
			local ball = gameProjectile:SeekingProjectile(closestTarget, player.x, player.y)
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
