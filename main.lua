local gameObjects = require("./gameobjects")
-- Set up global variables or constants
local gameEntity = gameObjects["gameEntity"]
local gameProjectile = gameObjects["gameProjectile"]
local player = gameEntity:Player()
local playerProjectiles = {}
local isRunning = true -- Game state flag

local function generateId()
	local id = 0.0
	return function()
		id = id + 1.0
		return id
	end
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

local testEnemy = gameEntity:Enemy()
local enemies = {}
enemies[getNextEnemyId()] = testEnemy
-- Update game logic (called every frame)
local movementKeysPressed = {}
function love.update(dt)
	if isRunning then
		for p_key, projectile in pairs(playerProjectiles) do
			-- TODO: determine whether to have projectile only collide with target,
			-- or allow collision with any target
			for e_key, enemy in pairs(enemies) do
				if detectCollision(projectile, enemy) then
					enemy.health = enemy.health - projectile.damage
					if enemy.health <= 0 then
						enemies[e_key] = nil
					end
					projectile.collisions = projectile.collisions - 1
					if projectile.collisions == 0 then
						playerProjectiles[p_key] = nil
					end
				end
			end
		end
		for _, enemy in pairs(enemies) do
			gameObjects.moveObjectTowardsTarget(enemy, player, dt)
		end
		for _, projectile in pairs(playerProjectiles) do
			gameObjects.moveObjectTowardsTarget(projectile, enemies[projectile.enemyId], dt)
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
		local closestTarget = gameObjects.getClosestObjectToTarget(player, enemies)
		if closestTarget ~= nil then
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
