local UI = require("functions/ui")
local Fonts = require("functions/fonts")
local Tween = require("functions/tween")

local Tutorial = {}

local step = 0
local active = false
local waiting_for = nil
local anim = { highlight_x = 0, highlight_y = 0, highlight_w = 0, highlight_h = 0, alpha = 0 }
local panel_anim = { alpha = 0, y_off = 20 }
local step_ready = false
local skip_hovered = false
local paused_for_step = false
local completed = false
local pending_advance = false
local advance_delay = 0

local steps = {}

local function buildSteps(W, H)
    steps = {
        -- 1: Welcome
        {
            title = "Welcome!",
            body = "Let me show you how to play.\nThis will only take a minute!",
            highlight = nil,
            wait_for = "click",
            phase = "intro",
        },
        -- 2: Wait for pre_roll to finish
        {
            title = "",
            body = "",
            highlight = nil,
            wait_for = "sub_state:choosing",
            phase = "round",
            silent = true,
        },
        -- 3: Target score
        {
            title = "Your Target",
            body = "Each round you need to beat a TARGET score.\nIf you don't reach it, it's game over!",
            highlight = function()
                return { x = 10, y = 10, w = W - 20, h = 50 }
            end,
            wait_for = "click",
            phase = "round",
        },
        -- 4: Rerolls
        {
            title = "Rerolls",
            body = "You get 3 rerolls per round.\nUse them wisely to improve your dice!",
            highlight = function()
                return { x = W * 0.55, y = 10, w = W * 0.25, h = 50 }
            end,
            wait_for = "click",
            phase = "round",
        },
        -- 5: Dice
        {
            title = "Your Dice",
            body = "These are your dice! Together they form a 'hand' - like poker, but with dice.\nThe better your hand, the more points you score.",
            highlight = function()
                return { x = 240, y = H * 0.2, w = W - 480, h = H * 0.35 }
            end,
            wait_for = "click",
            phase = "round",
        },
        -- 6: Hand reference
        {
            title = "Hand Reference",
            body = "This panel shows all the hands you can make.\nHigher hands on the list are worth more points!",
            highlight = function()
                return { x = W - 230, y = 70, w = 220, h = H * 0.5 }
            end,
            wait_for = "click",
            phase = "round",
        },
        -- 7: Score preview
        {
            title = "Score Preview",
            body = "This shows your current hand and estimated score.\nIt updates live as you lock and unlock dice!",
            highlight = function()
                return { x = 10, y = 70, w = 220, h = 190 }
            end,
            wait_for = "click",
            phase = "round",
        },
        -- 8: Lock a die
        {
            title = "Lock a Die!",
            body = "Click on any die to LOCK it.\nLocked dice keep their value when you reroll.\nTry it now!",
            highlight = function()
                return { x = 240, y = H * 0.2, w = W - 480, h = H * 0.35 }
            end,
            wait_for = "action:lock",
            phase = "round",
            arrow_text = "Lock a die to continue",
        },
        -- 9: Reroll
        {
            title = "Now Reroll!",
            body = "Hit the REROLL button below.\nYour unlocked dice will get brand new values,\nbut your locked ones stay safe!",
            highlight = function()
                local btn_w = 180
                return { x = W / 2 - btn_w - 20, y = H * 0.72, w = btn_w, h = 48 }
            end,
            wait_for = "action:reroll",
            phase = "round",
            arrow_text = "Click REROLL to continue",
        },
        -- 10: After reroll
        {
            title = "Nice!",
            body = "See how your locked dice stayed the same?\nYou can keep locking and rerolling to build a better hand.\nWhen you're happy, it's time to score!",
            highlight = function()
                return { x = 240, y = H * 0.2, w = W - 480, h = H * 0.35 }
            end,
            wait_for = "click",
            phase = "round",
        },
        -- 11: Score button
        {
            title = "Score Your Hand!",
            body = "Click SCORE to submit your hand and see if you beat the target!",
            highlight = function()
                local btn_w = 180
                return { x = W / 2 + 20, y = H * 0.72, w = btn_w, h = 48 }
            end,
            wait_for = "action:score",
            phase = "round",
            arrow_text = "Click SCORE to continue",
        },
        -- 12: Wait for scoring animation
        {
            title = "",
            body = "",
            highlight = nil,
            wait_for = "sub_state:scoring_done",
            phase = "round",
            silent = true,
        },
        -- 13: Score result
        {
            title = "You Did It!",
            body = "You beat the target! Great job!\nEach round, the target gets harder.\nClick the CONTINUE button to visit the shop!",
            highlight = function()
                local panel_w = 420
                local px = (W - panel_w) / 2
                return { x = px - 10, y = H * 0.18 - 10, w = panel_w + 20, h = 340 }
            end,
            wait_for = "state:shop",
            phase = "round",
            arrow_text = "Click CONTINUE below to proceed",
        },
        -- 15: Shop - hand upgrades
        {
            title = "Hand Upgrades",
            body = "Spend your money to UPGRADE hands.\nThis boosts their base score and multiplier.\nYour first pick each shop visit is FREE!",
            highlight = function()
                local section_w = W / 3 - 30
                return { x = 20, y = 160, w = section_w, h = H - 250 }
            end,
            wait_for = "click",
            phase = "shop",
        },
        -- 16: Shop - dice
        {
            title = "Special Dice",
            body = "Buy special dice with unique abilities!\nThey replace one of your current dice.\nEach type has a different power.",
            highlight = function()
                local section_w = W / 3 - 30
                return { x = W / 3 + 5, y = 160, w = section_w, h = H - 250 }
            end,
            wait_for = "click",
            phase = "shop",
        },
        -- 17: Shop - items
        {
            title = "Items",
            body = "Items give you passive bonuses every round.\nExtra rerolls, bonus points, multiplier boosts...\nCollect them to get stronger!",
            highlight = function()
                local section_w = W / 3 - 30
                return { x = 2 * W / 3 + 10, y = 160, w = section_w, h = H - 250 }
            end,
            wait_for = "click",
            phase = "shop",
        },
        -- 18: Shop - extra die
        {
            title = "Extra Dice",
            body = "See the '+' slot? Buy extra dice to grow your pool!\nWith 6+ dice you unlock powerful new hands\nlike Full Run and Three Pairs.",
            highlight = function()
                local count = 5
                local max_total = W * 0.7
                local die_size = math.min(60, math.floor((max_total - (count) * 8) / (count + 1)))
                local gap = math.min(12, math.floor((max_total - (count + 1) * die_size) / math.max(count, 1)))
                local total = (count + 1) * die_size + count * gap
                local start_x = (W - total) / 2
                local gx = start_x + count * (die_size + gap)
                return { x = gx - 5, y = 75, w = die_size + 10, h = die_size + 25 }
            end,
            wait_for = "click",
            phase = "shop",
        },
        -- 19: Shop - continue
        {
            title = "Continue!",
            body = "When you're done shopping, hit CONTINUE\nto start the next round.\nGo ahead and click it now!",
            highlight = function()
                local btn_w = 220
                return { x = (W - btn_w) / 2, y = H - 70, w = btn_w, h = 52 }
            end,
            wait_for = "action:continue",
            phase = "shop",
            arrow_text = "Click CONTINUE to finish",
        },
        -- 20: Done
        {
            title = "You're Ready!",
            body = "That's everything you need to know!\nStart a New Game to play for real.\nGood luck, and have fun!",
            highlight = nil,
            wait_for = "click",
            phase = "outro",
        },
    }
end

function Tutorial:init()
    step = 1
    active = true
    completed = false
    paused_for_step = false
    pending_advance = false
    advance_delay = 0

    local W, H = love.graphics.getDimensions()
    buildSteps(W, H)

    anim = { highlight_x = W / 2, highlight_y = H / 2, highlight_w = 0, highlight_h = 0, alpha = 0 }
    Tween.to(anim, 0.3, { alpha = 1 }, "outCubic")
    panel_anim = { alpha = 0, y_off = 20 }
    Tween.to(panel_anim, 0.4, { alpha = 1, y_off = 0 }, "outCubic")

    step_ready = true
    self:applyStep()
end

function Tutorial:isActive()
    return active
end

function Tutorial:isCompleted()
    return completed
end

function Tutorial:getPhase()
    if step < 1 or step > #steps then return nil end
    return steps[step].phase
end

function Tutorial:isSilent()
    if step < 1 or step > #steps then return false end
    return steps[step].silent == true
end

function Tutorial:shouldBlockInput()
    if not active then return false end
    if step < 1 or step > #steps then return false end
    local s = steps[step]
    if s.silent then return false end
    if s.wait_for == "click" then return true end
    return false
end

function Tutorial:applyStep()
    if step < 1 or step > #steps then return end
    local W, H = love.graphics.getDimensions()
    buildSteps(W, H)

    local s = steps[step]
    if s.highlight then
        local r = s.highlight()
        Tween.to(anim, 0.35, {
            highlight_x = r.x, highlight_y = r.y,
            highlight_w = r.w, highlight_h = r.h,
        }, "outCubic")
    else
        Tween.to(anim, 0.35, {
            highlight_x = 0, highlight_y = 0,
            highlight_w = W, highlight_h = H,
        }, "outCubic")
    end

    panel_anim = { alpha = 0, y_off = 15 }
    Tween.to(panel_anim, 0.3, { alpha = 1, y_off = 0 }, "outCubic")
    step_ready = true
end

function Tutorial:advance()
    if not active then return end
    step = step + 1
    if step > #steps then
        self:finish()
        return
    end
    self:applyStep()
end

function Tutorial:finish()
    active = false
    completed = true
    step = 0
end

function Tutorial:update(dt)
    if not active then return end
    if advance_delay > 0 then
        advance_delay = advance_delay - dt
        if advance_delay <= 0 then
            advance_delay = 0
            if pending_advance then
                pending_advance = false
                self:advance()
            end
        end
    end
end

function Tutorial:notifyAction(action)
    if not active then return end
    if pending_advance then return end
    if step < 1 or step > #steps then return end
    local s = steps[step]

    if s.wait_for == "action:" .. action then
        pending_advance = true
        advance_delay = 0.3
    end
end

function Tutorial:notifySubState(sub_state, extra)
    if not active then return end
    if pending_advance then return end
    if step < 1 or step > #steps then return end
    local s = steps[step]

    if s.wait_for == "sub_state:" .. sub_state then
        pending_advance = true
        advance_delay = 0.15
    end

    if s.wait_for == "sub_state:scoring_done" and sub_state == "scoring" then
        if extra and extra.timer and extra.timer > 2.0 then
            pending_advance = true
            advance_delay = 0.1
        end
    end
end

function Tutorial:notifyStateChange(new_state)
    if not active then return end
    if pending_advance then return end
    if step < 1 or step > #steps then return end
    local s = steps[step]
    if s.wait_for == "state:" .. new_state then
        pending_advance = true
        advance_delay = 0.5
    end
end

function Tutorial:draw()
    if not active then return end
    if step < 1 or step > #steps then return end
    local s = steps[step]
    if s.silent then return end

    local W, H = love.graphics.getDimensions()

    if anim.highlight_w > 0 and anim.highlight_h > 0 then
        if anim.highlight_w >= W - 1 and anim.highlight_h >= H - 1 then
            love.graphics.setColor(0, 0, 0, 0.75 * anim.alpha)
            love.graphics.rectangle("fill", 0, 0, W, H)
        else
            UI.drawSpotlight(
                anim.highlight_x, anim.highlight_y,
                anim.highlight_w, anim.highlight_h,
                0.7 * anim.alpha, 10
            )
        end
    end

    local panel_w = 340
    local panel_x, panel_y

    if s.highlight then
        local r = s.highlight()
        local center_x = r.x + r.w / 2
        panel_x = math.max(12, math.min(center_x - panel_w / 2, W - panel_w - 12))

        if r.y > H * 0.5 then
            panel_y = r.y - 160
        else
            panel_y = r.y + r.h + 16
        end
        panel_y = math.max(12, math.min(panel_y, H - 200))
    else
        panel_x = (W - panel_w) / 2
        panel_y = H * 0.3
    end

    panel_y = panel_y + panel_anim.y_off

    love.graphics.setColor(1, 1, 1, panel_anim.alpha)
    local arrow = s.arrow_text or "Click to continue"
    UI.drawTutorialPanel(panel_x, panel_y, panel_w, s.title, s.body, { arrow_text = arrow })

    local visible_step = 0
    local visible_total = 0
    for i, st in ipairs(steps) do
        if not st.silent then
            visible_total = visible_total + 1
            if i <= step then visible_step = visible_total end
        end
    end
    local step_text = visible_step .. " / " .. visible_total
    love.graphics.setFont(Fonts.get(11))
    love.graphics.setColor(UI.colors.text_dark[1], UI.colors.text_dark[2], UI.colors.text_dark[3], panel_anim.alpha * 0.7)
    love.graphics.printf(step_text, 0, H - 30, W * 0.5, "center")

    local skip_font = Fonts.get(14)
    local skip_text = "Skip Tutorial"
    local skip_w = skip_font:getWidth(skip_text) + 20
    local skip_x = W - skip_w - 12
    local skip_y = H - 36
    local mx, my = love.mouse.getPosition()
    skip_hovered = UI.pointInRect(mx, my, skip_x, skip_y, skip_w, 28)

    love.graphics.setFont(skip_font)
    if skip_hovered then
        love.graphics.setColor(UI.colors.red[1], UI.colors.red[2], UI.colors.red[3], panel_anim.alpha)
    else
        love.graphics.setColor(UI.colors.text_dim[1], UI.colors.text_dim[2], UI.colors.text_dim[3], panel_anim.alpha * 0.7)
    end
    love.graphics.printf(skip_text, skip_x, skip_y + 4, skip_w, "center")
end

function Tutorial:mousepressed(x, y, button)
    if not active then return false end
    if step < 1 or step > #steps then return false end

    if skip_hovered then
        self:finish()
        return true
    end

    local s = steps[step]
    if s.silent then return false end

    if s.wait_for == "click" then
        self:advance()
        return true
    end

    return false
end

function Tutorial:keypressed(key)
    if not active then return false end
    if step < 1 or step > #steps then return false end
    local s = steps[step]
    if s.silent then return false end

    if key == "escape" then
        self:finish()
        return true
    end

    if s.wait_for == "click" then
        if key == "return" or key == "space" then
            self:advance()
            return true
        end
    end

    return false
end

return Tutorial
