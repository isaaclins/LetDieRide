local Player = require("objects/player")
local Die = require("objects/die")
local createHands = require("content/hands")
local createDiceTypes = require("content/dice_types")
local createItems = require("content/items")
local createBosses = require("content/bosses")

local Splash = require("states/splash")
local RoundState = require("states/round")
local ShopState = require("states/shop_state")
local GameOverState = require("states/game_over")

local state = "splash"
local player = nil
local all_dice_types = nil
local all_items = nil
local all_bosses = nil
local current_boss = nil

local fonts = {}

local function initNewGame()
    player = Player:new()
    all_dice_types = createDiceTypes()
    all_items = createItems()
    all_bosses = createBosses()

    player.hands = createHands()

    for i = 1, 5 do
        table.insert(player.dice_pool, Die:new({
            name = "Vanilla Die",
            color = "black",
            die_type = "vanilla",
            ability_name = "None",
            ability_desc = "A standard die.",
        }))
    end

    current_boss = nil
    state = "round"
    RoundState:init(player, nil)
end

local function startRound()
    current_boss = nil
    if player:isBossRound() then
        current_boss = all_bosses[math.random(1, #all_bosses)]
    end
    RoundState:init(player, current_boss)
end

function love.load()
    love.graphics.setBackgroundColor(0.06, 0.06, 0.12)
    math.randomseed(os.time())

    fonts.default = love.graphics.newFont(16)
    love.graphics.setFont(fonts.default)

    love.window.setIcon(love.image.newImageData("content/icon/icon.png"))
    love.window.setTitle("Dice × Balatro")
    love.window.setMode(1280, 720, {
        highdpi = true,
        resizable = true,
        minwidth = 960,
        minheight = 540,
    })

    Splash:init()
end

function love.update(dt)
    if state == "splash" then
        Splash:update(dt)
    elseif state == "round" then
        RoundState:update(dt, player)
    elseif state == "shop" then
        ShopState:update(dt)
    elseif state == "game_over" then
        GameOverState:update(dt)
    end
end

function love.draw()
    if state == "splash" then
        Splash:draw()
    elseif state == "round" then
        RoundState:draw(player, current_boss)
    elseif state == "shop" then
        ShopState:draw(player)
    elseif state == "game_over" then
        GameOverState:draw(player)
    end
end

function love.mousepressed(x, y, button)
    local result = nil

    if state == "splash" then
        result = Splash:mousepressed(x, y, button)
    elseif state == "round" then
        result = RoundState:mousepressed(x, y, button, player)
    elseif state == "shop" then
        result = ShopState:mousepressed(x, y, button, player)
    elseif state == "game_over" then
        result = GameOverState:mousepressed(x, y, button)
    end

    handleResult(result)
end

function love.keypressed(key)
    local result = nil

    if state == "splash" then
        result = Splash:keypressed(key)
    elseif state == "round" then
        result = RoundState:keypressed(key, player)
    elseif state == "shop" then
        result = ShopState:keypressed(key)
    elseif state == "game_over" then
        result = GameOverState:keypressed(key)
    end

    handleResult(result)
end

function handleResult(result)
    if not result then return end

    if result == "start_game" then
        initNewGame()
    elseif result == "exit" then
        love.event.quit()
    elseif result == "to_shop" then
        local boss_ctx = RoundState:getBossContext()
        if current_boss and boss_ctx then
            current_boss:revertModifier(boss_ctx)
        end
        state = "shop"
        ShopState:init(player, all_dice_types, all_items)
    elseif result == "next_round" then
        player.round = player.round + 1
        state = "round"
        startRound()
    elseif result == "game_over" then
        local boss_ctx = RoundState:getBossContext()
        if current_boss and boss_ctx then
            current_boss:revertModifier(boss_ctx)
        end
        state = "game_over"
        GameOverState:init()
    elseif result == "restart" then
        state = "splash"
        Splash:init()
    end
end

function love.focus(f)
    if not f then
        print("LOST FOCUS")
    else
        print("GAINED FOCUS")
    end
end

function love.quit()
    print("Thanks for playing! Come back soon!")
end
