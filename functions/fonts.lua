local Fonts = {}
local cache = {}

function Fonts.get(size)
    if not cache[size] then
        cache[size] = love.graphics.newFont(size)
    end
    return cache[size]
end

return Fonts
