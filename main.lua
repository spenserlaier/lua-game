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
local function getSign(num)
	if num == nil then
		return nil
	end
	local sign = (num > 0) and 1 or (num < 0 and -1 or 0)
	return sign
end

local function generateEnemyAroundPlayer(player, radius, angleRadian)
	local offsetX = (radius * math.cos(angleRadian))
	local offsetY = (radius * math.sin(angleRadian))
	local enemy = gameEntity:Enemy()
	enemy.x = player.x + offsetX
	enemy.y = player.y + offsetY
	--TODO: also check for collisions with existing enemies
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
	local obj1CenterX = obj1.x + obj1.size / 2
	local obj1CenterY = obj1.y + obj1.size / 2
	local obj2CenterX = obj2.x + obj2.size / 2
	local obj2CenterY = obj2.y + obj2.size / 2
	return math.abs(obj1CenterX - obj2CenterX) < (obj1.size + obj2.size)
		and math.abs(obj1CenterY - obj2CenterY) < (obj1.size + obj2.size)
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
		local forces = {}
		for idx1, enemy1 in pairs(enemies) do
			local oldX = enemy1.x
			local oldY = enemy1.y
			gameObjects.moveObjectTowardsTarget(enemy1, player, dt)
			local xDiff = enemy1.x - oldX
			local yDiff = enemy1.y - oldY
			enemy1.x = oldX
			enemy1.y = oldY
			-- TODO: what about a set/table tracking enemies we've checked already?
			if forces[enemy1] == nil then
				forces[enemy1] = { x = xDiff, y = yDiff }
			end
			for idx2, enemy2 in pairs(enemies) do
				if idx2 == idx1 then
					goto continue
				end
				if detectCollision(enemy1, enemy2) then
					--TODO: maybe make force proportional to distance between objects?
					--i.e. closer == more pushback
					if forces[enemy2] == nil then
						local oldX2 = enemy2.x
						local oldY2 = enemy2.y
						gameObjects.moveObjectTowardsTarget(enemy2, player, dt)
						forces[enemy2] = { x = enemy2.x - oldX2, y = enemy2.y - oldY2 }
						enemy2.x = oldX2
						enemy2.y = oldY2
					end
					-- bounce the first enemy back
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

				::continue::
			end
		end
		for enemy, force in pairs(forces) do
			--print(force.x, force.y)
			-- idea: store old force x and y values, and do some kind of linear
			-- interpolation if the direction of the force changes
			local oldXSign = getSign(enemy.oldForceX)
			local oldYSign = getSign(enemy.oldForceY)
			local newXSign = getSign(force.x)
			local newYSign = getSign(force.y)
			--if oldXSign ~= newXSign and oldXSign ~= nil then
			if oldXSign ~= nil then
				local lerpForce = (enemy.oldForceX + force.x) / 10
				force.x = lerpForce
				--enemy.x = enemy.x + lerpForce
			end

			--if oldYSign ~= newYSign and oldYSign ~= nil then
			if oldYSign ~= nil then
				local lerpForce = (enemy.oldForceY + force.y) / 10
				force.y = lerpForce
			end
			--if math.abs(force.x) >= 0.05 then
			enemy.x = enemy.x + force.x
			--else
			--force.x = 0
			--end
			--if math.abs(force.y) >= 0.05 then
			enemy.y = enemy.y + force.y
			--else
			--force.y = 0
			--end
			enemy.oldForceX = force.x
			enemy.oldForceY = force.y
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
