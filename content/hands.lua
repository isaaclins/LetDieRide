local Hand = require("objects/hand")

local function createHands()
    return {
        Hand:new({
            name = "High Roll",
            base_score = 5,
            multiplier = 1,
            priority = 1,
            description = "Highest single die",
        }),
        Hand:new({
            name = "Pair",
            base_score = 10,
            multiplier = 1.5,
            priority = 2,
            description = "Two dice of the same value",
        }),
        Hand:new({
            name = "Two Pair",
            base_score = 20,
            multiplier = 1.5,
            priority = 3,
            description = "Two different pairs",
        }),
        Hand:new({
            name = "Three of a Kind",
            base_score = 30,
            multiplier = 2,
            priority = 4,
            description = "Three dice of the same value",
        }),
        Hand:new({
            name = "Small Straight",
            base_score = 30,
            multiplier = 2.5,
            priority = 5,
            description = "Four consecutive values",
        }),
        Hand:new({
            name = "Full House",
            base_score = 40,
            multiplier = 2.5,
            priority = 6,
            description = "Three of a kind + a pair",
        }),
        Hand:new({
            name = "Large Straight",
            base_score = 45,
            multiplier = 3,
            priority = 7,
            description = "Five consecutive values",
        }),
        Hand:new({
            name = "Four of a Kind",
            base_score = 60,
            multiplier = 3.5,
            priority = 8,
            description = "Four dice of the same value",
        }),
        Hand:new({
            name = "Five of a Kind",
            base_score = 100,
            multiplier = 5,
            priority = 9,
            description = "All five dice the same value",
        }),
    }
end

return createHands
