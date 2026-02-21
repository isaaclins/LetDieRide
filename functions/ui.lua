local UI = {}

UI.colors = {
    bg           = { 0.06, 0.06, 0.12, 1 },
    panel        = { 0.11, 0.11, 0.20, 1 },
    panel_light  = { 0.16, 0.16, 0.28, 1 },
    panel_hover  = { 0.20, 0.20, 0.34, 1 },
    accent       = { 1.00, 0.84, 0.00, 1 },
    accent_dim   = { 0.80, 0.65, 0.00, 1 },
    green        = { 0.20, 0.78, 0.40, 1 },
    red          = { 0.90, 0.22, 0.22, 1 },
    blue         = { 0.30, 0.50, 0.90, 1 },
    blue_hover   = { 0.40, 0.60, 1.00, 1 },
    text         = { 1.00, 1.00, 1.00, 1 },
    text_dim     = { 0.55, 0.55, 0.65, 1 },
    text_dark    = { 0.30, 0.30, 0.40, 1 },
    die_white    = { 0.95, 0.93, 0.88, 1 },
    die_black    = { 0.15, 0.15, 0.15, 1 },
    die_blue     = { 0.20, 0.40, 0.85, 1 },
    die_green    = { 0.15, 0.65, 0.30, 1 },
    die_red      = { 0.85, 0.20, 0.20, 1 },
    locked_tint  = { 0.85, 0.15, 0.15, 0.35 },
    free_badge   = { 0.15, 0.75, 0.30, 1 },
    shadow       = { 0.00, 0.00, 0.00, 0.40 },
}

local dot_positions = {
    [1] = { { 0.5, 0.5 } },
    [2] = { { 0.27, 0.27 }, { 0.73, 0.73 } },
    [3] = { { 0.27, 0.27 }, { 0.5, 0.5 }, { 0.73, 0.73 } },
    [4] = { { 0.27, 0.27 }, { 0.73, 0.27 }, { 0.27, 0.73 }, { 0.73, 0.73 } },
    [5] = { { 0.27, 0.27 }, { 0.73, 0.27 }, { 0.5, 0.5 }, { 0.27, 0.73 }, { 0.73, 0.73 } },
    [6] = { { 0.27, 0.27 }, { 0.73, 0.27 }, { 0.27, 0.5 }, { 0.73, 0.5 }, { 0.27, 0.73 }, { 0.73, 0.73 } },
}

function UI.setColor(c)
    love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
end

function UI.roundRect(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r, r)
end

function UI.drawShadow(x, y, w, h, r, offset)
    offset = offset or 4
    UI.setColor(UI.colors.shadow)
    UI.roundRect("fill", x + offset, y + offset, w, h, r or 8)
end

function UI.drawButton(text, x, y, w, h, opts)
    opts = opts or {}
    local mx, my = love.mouse.getPosition()
    local hovered = mx >= x and mx <= x + w and my >= y and my <= y + h
    local r = opts.radius or 8
    local font = opts.font or love.graphics.getFont()

    UI.drawShadow(x, y, w, h, r)

    if opts.disabled then
        UI.setColor(UI.colors.panel)
    elseif hovered then
        UI.setColor(opts.hover_color or UI.colors.blue_hover)
    else
        UI.setColor(opts.color or UI.colors.blue)
    end
    UI.roundRect("fill", x, y, w, h, r)

    if opts.disabled then
        UI.setColor(UI.colors.text_dark)
    else
        UI.setColor(opts.text_color or UI.colors.text)
    end
    local prev_font = love.graphics.getFont()
    love.graphics.setFont(font)
    love.graphics.printf(text, x, y + (h - font:getHeight()) / 2, w, "center")
    love.graphics.setFont(prev_font)

    return hovered
end

function UI.drawDie(x, y, size, value, dot_color, body_color, locked, hovered, special_glow)
    local r = size * 0.12

    UI.drawShadow(x, y, size, size, r, 3)

    UI.setColor(body_color or UI.colors.die_white)
    UI.roundRect("fill", x, y, size, size, r)

    if special_glow then
        love.graphics.setLineWidth(2)
        UI.setColor(special_glow)
        UI.roundRect("line", x - 1, y - 1, size + 2, size + 2, r)
        love.graphics.setLineWidth(1)
    end

    if hovered and not locked then
        love.graphics.setColor(1, 1, 1, 0.12)
        UI.roundRect("fill", x, y, size, size, r)
    end

    local dot_r = size * 0.085
    local positions = dot_positions[value] or dot_positions[1]
    UI.setColor(dot_color or UI.colors.die_black)
    for _, pos in ipairs(positions) do
        love.graphics.circle("fill", x + pos[1] * size, y + pos[2] * size, dot_r)
    end

    if locked then
        UI.setColor(UI.colors.locked_tint)
        UI.roundRect("fill", x, y, size, size, r)
        love.graphics.setColor(1, 0.3, 0.3, 0.9)
        local lock_font = love.graphics.getFont()
        love.graphics.printf("LOCKED", x, y + size * 0.4, size, "center")
    end
end

function UI.drawPanel(x, y, w, h, opts)
    opts = opts or {}
    local r = opts.radius or 10
    UI.drawShadow(x, y, w, h, r)
    UI.setColor(opts.color or UI.colors.panel)
    UI.roundRect("fill", x, y, w, h, r)
    if opts.border then
        love.graphics.setLineWidth(opts.border_width or 2)
        UI.setColor(opts.border)
        UI.roundRect("line", x, y, w, h, r)
        love.graphics.setLineWidth(1)
    end
end

function UI.pointInRect(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

function UI.drawBadge(text, x, y, color, font)
    font = font or love.graphics.getFont()
    local tw = font:getWidth(text) + 12
    local th = font:getHeight() + 4
    UI.setColor(color or UI.colors.free_badge)
    UI.roundRect("fill", x, y, tw, th, 4)
    UI.setColor(UI.colors.text)
    local prev = love.graphics.getFont()
    love.graphics.setFont(font)
    love.graphics.printf(text, x, y + 2, tw, "center")
    love.graphics.setFont(prev)
    return tw
end

function UI.lerp(a, b, t)
    return a + (b - a) * t
end

function UI.clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

return UI
