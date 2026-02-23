local Class = require("objects/class")
local Boss = Class:extend()

function Boss:init(opts)
	opts = opts or {}
	self.name = opts.name or "Unknown Boss"
	self.description = opts.description or ""
	self.modifier = opts.modifier or function() end
	self.revert = opts.revert or function() end
	self.icon = opts.icon or "!"
end

function Boss:applyModifier(context)
	self.modifier(self, context)
end

function Boss:revertModifier(context)
	self.revert(self, context)
end

return Boss
