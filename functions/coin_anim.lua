local CoinAnim = {}

local FRAME_COUNT = 6
local FPS = 8

local frames = {}
local timer = 0
local frame_index = 1
local base_w, base_h = 0, 0

function CoinAnim.load()
	for i = 1, FRAME_COUNT do
		frames[i] = love.graphics.newImage("content/icon/currency/silver/" .. i .. ".png")
		frames[i]:setFilter("nearest", "nearest")
	end
	base_w = frames[1]:getWidth()
	base_h = frames[1]:getHeight()
end

function CoinAnim.update(dt)
	timer = timer + dt
	local interval = 1 / FPS
	while timer >= interval do
		timer = timer - interval
		frame_index = (frame_index % FRAME_COUNT) + 1
	end
end

function CoinAnim.draw(x, y, scale)
	scale = scale or 1
	if #frames == 0 then
		return
	end
	love.graphics.draw(frames[frame_index], x, y, 0, scale, scale)
end

function CoinAnim.drawStatic(x, y, scale)
	scale = scale or 1
	if #frames == 0 then
		return
	end
	love.graphics.draw(frames[1], x, y, 0, scale, scale)
end

function CoinAnim.getWidth(scale)
	return base_w * (scale or 1)
end

function CoinAnim.getHeight(scale)
	return base_h * (scale or 1)
end

function CoinAnim.drawWithAmount(amount_str, x, y, align, max_w, scale)
	scale = scale or 1
	local coin_w = CoinAnim.getWidth(scale)
	local coin_h = CoinAnim.getHeight(scale)
	local font = love.graphics.getFont()
	local text_w = font:getWidth(amount_str)
	local text_h = font:getHeight()
	local gap = math.max(1, math.floor(2 * scale))
	local total_w = coin_w + gap + text_w

	local draw_x = x
	if align == "right" then
		draw_x = x + max_w - total_w
	elseif align == "center" then
		draw_x = x + (max_w - total_w) / 2
	end

	local coin_y = y + (text_h - coin_h) / 2
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(1, 1, 1, a)
	CoinAnim.draw(draw_x, coin_y, scale)
	love.graphics.setColor(r, g, b, a)
	love.graphics.print(amount_str, draw_x + coin_w + gap, y)

	return total_w
end

function CoinAnim.drawStaticWithAmount(amount_str, x, y, align, max_w, scale)
	scale = scale or 1
	local coin_w = CoinAnim.getWidth(scale)
	local coin_h = CoinAnim.getHeight(scale)
	local font = love.graphics.getFont()
	local text_w = font:getWidth(amount_str)
	local text_h = font:getHeight()
	local gap = math.max(1, math.floor(2 * scale))
	local total_w = coin_w + gap + text_w

	local draw_x = x
	if align == "right" then
		draw_x = x + max_w - total_w
	elseif align == "center" then
		draw_x = x + (max_w - total_w) / 2
	end

	local coin_y = y + (text_h - coin_h) / 2
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(1, 1, 1, a)
	CoinAnim.drawStatic(draw_x, coin_y, scale)
	love.graphics.setColor(r, g, b, a)
	love.graphics.print(amount_str, draw_x + coin_w + gap, y)

	return total_w
end

return CoinAnim
