local UI = require("functions/ui")
local Fonts = require("functions/fonts")

local Splash = {}

local title_y_offset = 0
local time_elapsed = 0
local floating_dice = {}

function Splash:init()
    time_elapsed = 0
    floating_dice = {}
    for i = 1, 12 do
        table.insert(floating_dice, {
            x = math.random(50, 1230),
            y = math.random(50, 670),
            value = math.random(1, 6),
            size = math.random(30, 50),
            speed = 0.3 + math.random() * 0.7,
            phase = math.random() * math.pi * 2,
            alpha = 0.08 + math.random() * 0.1,
        })
    end
end

function Splash:update(dt)
    time_elapsed = time_elapsed + dt
    title_y_offset = math.sin(time_elapsed * 1.5) * 6

    for _, d in ipairs(floating_dice) do
        d.phase = d.phase + dt * d.speed
        d.y = d.y + math.sin(d.phase) * 0.3
    end
end

function Splash:draw()
    local W, H = love.graphics.getDimensions()

    UI.setColor(UI.colors.bg)
    love.graphics.rectangle("fill", 0, 0, W, H)

    for _, d in ipairs(floating_dice) do
        love.graphics.setColor(0.95, 0.93, 0.88, d.alpha)
        UI.roundRect("fill", d.x, d.y, d.size, d.size, d.size * 0.12)
    end

    love.graphics.setFont(Fonts.get(64))
    UI.setColor(UI.colors.accent)
    love.graphics.printf("DICE × BALATRO", 0, H * 0.2 + title_y_offset, W, "center")

    love.graphics.setFont(Fonts.get(22))
    UI.setColor(UI.colors.text_dim)
    love.graphics.printf("A Yahtzee Roguelike", 0, H * 0.2 + 80 + title_y_offset, W, "center")

    local btn_w, btn_h = 260, 56
    local btn_x = (W - btn_w) / 2
    local btn_y_start = H * 0.52

    self._new_game_hovered = UI.drawButton(
        "NEW GAME", btn_x, btn_y_start, btn_w, btn_h,
        { font = Fonts.get(26), color = UI.colors.green, hover_color = { 0.25, 0.85, 0.45, 1 } }
    )

    self._exit_hovered = UI.drawButton(
        "EXIT", btn_x, btn_y_start + 76, btn_w, btn_h,
        { font = Fonts.get(26), color = UI.colors.red, hover_color = { 0.95, 0.30, 0.30, 1 } }
    )

    love.graphics.setFont(Fonts.get(14))
    UI.setColor(UI.colors.text_dark)
    love.graphics.printf("Roll. Lock. Score. Survive.", 0, H - 40, W, "center")
end

function Splash:mousepressed(x, y, button)
    if button == 1 then
        if self._new_game_hovered then
            return "start_game"
        elseif self._exit_hovered then
            return "exit"
        end
    end
    return nil
end

function Splash:keypressed(key)
    if key == "return" or key == "space" then
        return "start_game"
    elseif key == "escape" then
        return "exit"
    end
    return nil
end

return Splash
