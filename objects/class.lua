local Class = {}
Class.__index = Class

function Class:new(...)
    local instance = setmetatable({}, self)
    if instance.init then
        instance:init(...)
    end
    return instance
end

function Class:extend()
    local cls = {}
    cls.__index = cls
    setmetatable(cls, { __index = self, __call = self.new })
    cls.super = self
    return cls
end

return Class
