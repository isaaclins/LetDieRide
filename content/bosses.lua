local Boss = require("objects/boss")
local RNG = require("functions/rng")

local function createBosses()
    return {
        Boss:new({
            name = "The Lockdown",
            description = "Locks 30% of your dice to random values",
            icon = "X",
            modifier = function(self, context)
                if context and context.player and #context.player.dice_pool > 0 then
                    local pool = context.player.dice_pool
                    local lock_count = math.max(1, math.ceil(#pool * 0.3))
                    local indices = {}
                    for i = 1, #pool do table.insert(indices, i) end
                    context.boss_locked_dice = {}
                    for _ = 1, lock_count do
                        if #indices == 0 then break end
                        local pick = RNG.random(1, #indices)
                        local idx = indices[pick]
                        table.remove(indices, pick)
                        local die = pool[idx]
                        die.locked = true
                        die.value = RNG.random(1, 6)
                        table.insert(context.boss_locked_dice, die)
                    end
                end
            end,
            revert = function(self, context)
                if context and context.boss_locked_dice then
                    for _, die in ipairs(context.boss_locked_dice) do
                        die.locked = false
                    end
                    context.boss_locked_dice = nil
                end
            end,
        }),
        Boss:new({
            name = "The Inverter",
            description = "All dice values are inverted (1/6, 2/5, 3/4)",
            icon = "~",
            modifier = function(self, context)
                if context and context.player then
                    context.invert_dice = true
                end
            end,
            revert = function(self, context)
                if context then
                    context.invert_dice = false
                end
            end,
        }),
        Boss:new({
            name = "The Collector",
            description = "Lose one random die after this round (replaced with Normal)",
            icon = "?",
            modifier = function(self, context)
                if context and context.player then
                    context.collector_active = true
                end
            end,
            revert = function(self, context)
                if context and context.collector_active and context.player then
                    local Die = require("objects/die")
                    local idx = RNG.random(1, #context.player.dice_pool)
                    context.player.dice_pool[idx] = Die:new({
                        name = "Normal Die",
                        color = "black",
                        die_type = "Normal",
                        ability_name = "None",
                    })
                    context.collector_active = false
                end
            end,
        }),
        Boss:new({
            name = "The Miser",
            description = "Rerolls reduced by 2 this round",
            icon = "-",
            modifier = function(self, context)
                if context and context.player then
                    context.player.rerolls_remaining = math.max(0, context.player.rerolls_remaining - 2)
                    context.miser_active = true
                end
            end,
            revert = function(self, context)
                if context then context.miser_active = false end
            end,
        }),
        Boss:new({
            name = "The Silencer",
            description = "All dice abilities are suppressed this round",
            icon = "!",
            modifier = function(self, context)
                if context then
                    context.suppress_abilities = true
                end
            end,
            revert = function(self, context)
                if context then context.suppress_abilities = false end
            end,
        }),
    }
end

return createBosses
