local Class = require("objects/class")
local RNG = require("functions/rng")
local Shop = Class:extend()

function Shop:init()
	self.hand_upgrades = {}
	self.dice_inventory = {}
	self.items_inventory = {}
	self.free_choice_used = false
	self.selected_section = 1
end

function Shop:generate(player, all_dice_types, all_items)
	self.free_choice_used = player.free_choice_used

	local all_upgradeable = {}
	local max_dice = player.max_dice or #player.dice_pool
	for i, hand in ipairs(player.hands) do
		if hand.upgrade_level < hand.max_upgrade and (hand.min_dice or 1) <= max_dice then
			table.insert(all_upgradeable, {
				hand_index = i,
				hand = hand,
				cost = hand:getUpgradeCost(),
			})
		end
	end
	self.hand_upgrades = {}
	for i = 1, math.min(5, #all_upgradeable) do
		local idx = RNG.random(1, #all_upgradeable)
		table.insert(self.hand_upgrades, all_upgradeable[idx])
		table.remove(all_upgradeable, idx)
	end

	self.dice_inventory = {}
	local available = {}
	for _, dt in ipairs(all_dice_types) do
		table.insert(available, dt)
	end
	for i = 1, math.min(3, #available) do
		local idx = RNG.random(1, #available)
		table.insert(self.dice_inventory, {
			die = available[idx]:clone(),
			cost = 8 + available[idx].upgrade_level * 4,
		})
		table.remove(available, idx)
	end

	self.items_inventory = {}
	local avail_items = {}
	for _, item in ipairs(all_items) do
		if item.condition and not item.condition(player) then
			goto continue_item
		end
		local owned = false
		for _, pi in ipairs(player.items) do
			if pi.name == item.name then
				owned = true
				break
			end
		end
		if not owned then
			if item.dynamic_cost then
				item.cost = item.dynamic_cost(player)
			end
			table.insert(avail_items, item)
		end
		::continue_item::
	end
	for i = 1, math.min(3, #avail_items) do
		local idx = RNG.random(1, #avail_items)
		table.insert(self.items_inventory, avail_items[idx])
		table.remove(avail_items, idx)
	end
end

function Shop:getBulkUpgradeCost(hand, count)
	local total = 0
	local level = hand.upgrade_level
	local max_lvl = hand.max_upgrade
	local actual = 0
	for _ = 1, count do
		if level >= max_lvl then
			break
		end
		local cost
		if level >= 5 then
			cost = 5 + level * level * 8
		else
			cost = 5 + level * level * 5
		end
		total = total + cost
		level = level + 1
		actual = actual + 1
	end
	return total, actual
end

function Shop:getBulkMaxCount(hand, budget)
	local level = hand.upgrade_level
	local max_lvl = hand.max_upgrade
	local total = 0
	local count = 0
	while level < max_lvl do
		local cost
		if level >= 5 then
			cost = 5 + level * level * 8
		else
			cost = 5 + level * level * 5
		end
		if total + cost > budget then
			break
		end
		total = total + cost
		level = level + 1
		count = count + 1
	end
	return count, total
end

function Shop:buyHandUpgrade(player, upgrade_index, bulk_count)
	local upgrade = self.hand_upgrades[upgrade_index]
	if not upgrade then
		return false, "Invalid upgrade"
	end

	if upgrade.hand.upgrade_level >= upgrade.hand.max_upgrade then
		return false, "Already maxed!"
	end

	if not self.free_choice_used then
		self.free_choice_used = true
		player.free_choice_used = true
		upgrade.hand:upgrade()
		upgrade.cost = upgrade.hand:getUpgradeCost()
		return true, "Free upgrade applied!"
	end

	local count = bulk_count or 1
	if count == 0 then
		count = 1
	end

	local total_cost, actual
	if count == -1 then
		actual, total_cost = self:getBulkMaxCount(upgrade.hand, player.currency)
	else
		total_cost, actual = self:getBulkUpgradeCost(upgrade.hand, count)
	end

	if actual == 0 then
		return false, "Already maxed!"
	end

	if player.currency < total_cost then
		return false, "Not enough currency"
	end

	player.currency = player.currency - total_cost
	for _ = 1, actual do
		upgrade.hand:upgrade()
	end
	upgrade.cost = upgrade.hand:getUpgradeCost()
	return true, "+" .. actual .. " levels!"
end

function Shop:buyDie(player, shop_die_index, player_die_index)
	local shop_entry = self.dice_inventory[shop_die_index]
	if not shop_entry then
		return false, "Invalid die"
	end

	if not self.free_choice_used then
		self.free_choice_used = true
		player.free_choice_used = true
		player:replaceDie(player_die_index, shop_entry.die)
		table.remove(self.dice_inventory, shop_die_index)
		return true, "Free replacement!"
	end

	if player.currency < shop_entry.cost then
		return false, "Not enough currency"
	end

	player.currency = player.currency - shop_entry.cost
	player:replaceDie(player_die_index, shop_entry.die)
	table.remove(self.dice_inventory, shop_die_index)
	return true, "Die replaced!"
end

function Shop:buyItem(player, item_index)
	local item = self.items_inventory[item_index]
	if not item then
		return false, "Invalid item"
	end

	if player.currency < item.cost then
		return false, "Not enough currency"
	end

	if item.consumable then
		local result = item.effect(item, { player = player })
		if result == false then
			return false, "Cannot use!"
		end
		player.currency = player.currency - item.cost
		if item.dynamic_cost then
			item.cost = item.dynamic_cost(player)
		else
			table.remove(self.items_inventory, item_index)
		end
		return true, item.name .. " activated!"
	end

	player.currency = player.currency - item.cost
	player:addItem(item)
	table.remove(self.items_inventory, item_index)
	return true, "Item purchased!"
end

return Shop
