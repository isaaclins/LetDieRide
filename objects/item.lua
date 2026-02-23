local Class = require("objects/class")
local Item = Class:extend()

function Item:init(opts)
	opts = opts or {}
	self.name = opts.name or "Unknown Item"
	self.description = opts.description or ""
	self.effect = opts.effect or function() end
	self.trigger_type = opts.trigger_type or "passive"
	self.icon = opts.icon or "?"
	self.cost = opts.cost or 10
	self.consumable = opts.consumable or false
	self.triggered_this_round = false
end

function Item:apply(context)
	if self.trigger_type == "once" and self.triggered_this_round then
		return
	end
	self.effect(self, context)
	if self.trigger_type == "once" then
		self.triggered_this_round = true
	end
end

function Item:resetRound()
	self.triggered_this_round = false
end

return Item
