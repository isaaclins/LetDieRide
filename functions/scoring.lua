local Scoring = {}

function Scoring.getCounts(values)
    local counts = {}
    for _, v in ipairs(values) do
        counts[v] = (counts[v] or 0) + 1
    end
    return counts
end

function Scoring.getSorted(values)
    local sorted = {}
    for _, v in ipairs(values) do
        table.insert(sorted, v)
    end
    table.sort(sorted)
    return sorted
end

function Scoring.hasConsecutive(sorted, n)
    local unique = {}
    local seen = {}
    for _, v in ipairs(sorted) do
        if not seen[v] then
            table.insert(unique, v)
            seen[v] = true
        end
    end
    table.sort(unique)

    if #unique < n then return false, {} end

    for i = 1, #unique - n + 1 do
        local is_seq = true
        for j = 1, n - 1 do
            if unique[i + j] ~= unique[i] + j then
                is_seq = false
                break
            end
        end
        if is_seq then
            local matched = {}
            for j = 0, n - 1 do
                table.insert(matched, unique[i + j])
            end
            return true, matched
        end
    end
    return false, {}
end

function Scoring.detectHand(values)
    local counts = Scoring.getCounts(values)
    local sorted = Scoring.getSorted(values)

    local pairs_found = {}
    local threes_found = {}
    local fours_found = {}
    local fives_found = {}

    for val, count in pairs(counts) do
        if count == 2 then table.insert(pairs_found, val) end
        if count == 3 then table.insert(threes_found, val) end
        if count == 4 then table.insert(fours_found, val) end
        if count == 5 then table.insert(fives_found, val) end
    end

    if #fives_found > 0 then
        return "Five of a Kind", values
    end

    local has_large, large_matched = Scoring.hasConsecutive(sorted, 5)
    if has_large then
        return "Large Straight", large_matched
    end

    if #fours_found > 0 then
        local matched = {}
        for _, v in ipairs(values) do
            if v == fours_found[1] then table.insert(matched, v) end
        end
        return "Four of a Kind", matched
    end

    if #threes_found > 0 and #pairs_found > 0 then
        return "Full House", values
    end

    local has_small, small_matched = Scoring.hasConsecutive(sorted, 4)
    if has_small then
        return "Small Straight", small_matched
    end

    if #threes_found > 0 then
        local matched = {}
        for _, v in ipairs(values) do
            if v == threes_found[1] then table.insert(matched, v) end
        end
        return "Three of a Kind", matched
    end

    if #pairs_found >= 2 then
        local matched = {}
        for _, v in ipairs(values) do
            for _, pv in ipairs(pairs_found) do
                if v == pv then
                    table.insert(matched, v)
                    break
                end
            end
        end
        return "Two Pair", matched
    end

    if #pairs_found == 1 then
        local matched = {}
        for _, v in ipairs(values) do
            if v == pairs_found[1] then table.insert(matched, v) end
        end
        return "Pair", matched
    end

    return "High Roll", { math.max(unpack(values)) }
end

function Scoring.findBestHand(values, hands_list)
    local hand_name, matched = Scoring.detectHand(values)
    for _, hand in ipairs(hands_list) do
        if hand.name == hand_name then
            local score = hand:calculateScore(values, matched)
            return hand, score, matched
        end
    end
    return hands_list[1], hands_list[1]:calculateScore(values, matched), matched
end

return Scoring
