
local modpath = minetest.get_modpath("mining")
dofile(modpath.. "/ore_carts.lua")

local mod_storage = minetest.get_mod_storage()

mining = {}
mining.data = {}
mining.objects = {}

mining.next_entity = mod_storage:get_int("next_entity") or 1
mining.entities = minetest.deserialize(mod_storage:get_string("entities")) or {}




function mk_digger_inv_on_put(id)
	return function(inv, listname, index, stack, player)
		print(id)
		local name = stack:get_name()
		
		if name == "default:coal_lump" then
		--	print(dump2(mining.objects))
			local obj = mining.objects[id]
		--	print("------------")
		----	print(dump2(obj))
			obj.data.fuel = obj.data.fuel + 10
		end
		
	end
end




if type(mining.entities) ~= "table" then
	mining.entities = {}
end



--print(dump(mining.entities))

-- recreate detached inventories
for id,v in pairs(mining.entities) do
	local inv1 = minetest.create_detached_inventory("mining_digger_"..id.."_hold", {
		on_put = mk_digger_inv_on_put(id),
	})
	
--	print(dump(inv1))
	
	inv1:set_size("main", 5 * 8)
	
	if v.inventories then
		inv1:set_lists(v.inventories[1])
	end
end


local function serialize_invlist(list) 
	local out = {}
	
	-- TODO: serialize metadata
	
	for k,v in pairs(list) do
		if type(v) == "userdata" then
			out[k] = v:to_string()
		else
			out[k] = v
		end
	end
	return out
end


local function serialize_inventory(id) 
	local inv = minetest.get_inventory({type="detached", name="mining_digger_"..id.."_hold"})
	local lists = inv:get_lists()
	local out = {}
	for id,v in pairs(lists) do
		out[id] = serialize_invlist(v)
	end
	return out
end


local function save_data() 
	--print("saving")
	mod_storage:set_int("next_entity", mining.next_entity);
	
	for id,v in pairs(mining.entities) do
		--print("id: "..id)
		v.inventories[1] = serialize_inventory(id)
	end
	
	--print(dump(mining.entities))
	
	mod_storage:set_string("entities", minetest.serialize(mining.entities))
	
end



local function deploy_digger(digger)
	local id = mining.next_entity
	mining.next_entity = mining.next_entity + 1
	
	digger.data = digger.data or {}
	digger.data.id = id
	digger.data.fuel = 0
	
	mining.objects[id] = digger
	
	mining.entities[id] = {
		id = id,
		inventories = {}
	}
	
	local inv1 = minetest.create_detached_inventory("mining_digger_"..id.."_hold", {
		on_put = mk_digger_inv_on_put(id),
	})

	inv1:set_size("main", 5 * 8)
	
	
	save_data()
end





local function get_digger_formspec(ent)
	local state_str = "Sailing"
	
	return "" ..
		"size[8,8;]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"list[detached:mining_digger_"..ent.data.id.."_hold;main;0,0;3,2;]"..
		"label[4,0;Fuel: "..ent.data.fuel.."]"..
		"button[5,1;2,.25;start;Start]" ..
		"button[5,2;2,.25;stop;Stop]" ..
		
		"list[current_player;main;0,3.25;8,1;]"..
		"list[current_player;main;0,4.5;8,3;8]"..
		"listring[context;dst]"..
		"listring[current_player;main]"..
		"listring[context;src]"..
		"listring[current_player;main]"..
		"listring[context;fuel]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 3.25)
end


local function get_digger_inv_formspec(digger, hold)
	local state_str = "Sailing"
	
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[context;hold;4,2;3,2;]"..
		"image[2,2.5;1,1;default_furnace_fire_bg.png]"..

		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;dst]"..
		"listring[current_player;main]"..
		"listring[context;src]"..
		"listring[current_player;main]"..
		"listring[context;fuel]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end






local function stepfn(self, dtime)
	
	if self.empty_carts == nil then
		self.empty_carts = 2
	end
	
	
	local v = {x=.2, y=0, z=0}
	

	local pos = self.object:getpos()
	local rpos = vector.round(pos)
	local yaw = self.object:getyaw() or 0
	
	local frontdir = vector.round(vector.normalize(v))
	local cross = {x=frontdir.z, y=0, z= -frontdir.x}
	
	
	-- what is in front of mob?
	local frontpos = vector.add(pos, vector.multiply(frontdir, 4))
	
	
	if not vector.equals(self.last_pos, rpos) then 
		self.state = "dig"
		self.last_pos = rpos
	end
	
	



	
	local stable = true
	local dug_node = false
	local cleared = true
	local ll = {}
	--print("state: "..self.state)
	if self.state == "dig" then
-- 		self.object:setvelocity({x=0,y=0,z=0})
		
			
		if not self.anim then
			self.object:set_animation({x = 0, y = 40}, 10, 0, true)
			self.anim = true
		end
		
		self.dig_timer = (self.dig_timer or 0) + dtime
		if self.dig_timer > 1 and self.empty_carts > 0 then 
			local eb = false
			self.advance = false

			for h = 0,3 do
				for w = -4,4 do
					local p = vector.add(frontpos, vector.multiply(cross, w))
					p.y = p.y + h
				--	print(minetest.pos_to_string(p))
					
					local fnode = minetest.get_node(p)
					
					if fnode.name ~= "air" then
						dug_node = true
						self.advance = false
					
						local drops =  minetest.get_node_drops(fnode.name)
						for _,d in ipairs(drops) do
							table.insert(ll, d)
						end
						minetest.set_node(p, {name="air"})
						
						eb = true
						break
					end
					
				end
				if eb then break end
			end
			
			
			if not dug_node then
				self.state = "advance"
			end
			
			self.dig_timer = self.dig_timer % 1
		end
		
	elseif self.state == "advance" then
		-- check for stable path forward
		
		for x = -1,1 do
			local p = vector.add(frontpos, vector.multiply(cross, x))
			p.y = p.y - 1
			
			local n = minetest.get_node(p)
			if n.name == "air" then
				--print("unstable")
				stable = false
				break
			end
			--print(dump2(p))
		end
	
	elseif self.state == "stop" then
		self.object:setvelocity({x=0,y=0,z=0})
		self.object:set_animation({x = 0, y = 0}, 10, 0, false)
		self.anim = nil
		self.advance = false
	end

	
	-- TODO: fix advancement logic
	if self.state == "advance" then
		--print("advance ")
		self.object:setvelocity(v)
	else
		--print("stop")
		self.object:setvelocity({x=0,y=0,z=0})
	end
	
	
	local out_rail = vector.add(pos, cross)
	local in_rail = vector.subtract(pos, cross)
	minetest.set_node(out_rail, {name="carts:rail"})
	minetest.set_node(in_rail, {name="carts:rail"})
	
	if #ll > 0 and self.empty_carts > 0 then
		local cart = minetest.add_entity(out_rail, "mining:ore_cart")
		if cart then
			local cc = cart:get_luaentity()
			cc.direction = vector.multiply(frontdir, -1)
			cc.contents = ll
			
			self.empty_carts = self.empty_carts - 1
		end
	end
	
	
	local all_objects = minetest.get_objects_inside_radius(in_rail, 1.2)
	local carts = {}
	local _,obj
	for _,obj in ipairs(all_objects) do
		if not obj:is_player() then
			if obj:get_luaentity().name == "mining:ore_cart" then
				obj:remove()
				self.empty_carts = self.empty_carts + 1
			end
		end
	end
		
end





local function rcfn(self, clicker) 
	
	if not clicker or not clicker:is_player() then
		return
	end
	--local name = clicker:get_player_name()
	
	minetest.show_formspec(clicker:get_player_name(), "mining:digger_formQ"..self.data.id, get_digger_formspec(self))
	
	
end



local function splitname(name)
	local c = string.find(name, "Q")
	if c == nil then return nil, nil end
	--print("c " ..c)
	return string.sub(name, 1,  c - 1), string.sub(name, c + 1, string.len(name))
end


minetest.register_on_player_receive_fields(function(player, formname, fields)
	
	
	local formprefix, id = splitname(formname)
	
	if formprefix ~= "mining:digger_form" then
		--print("wrong prefix: " .. formname .. " - " .. formprefix)
		return
	end
	
	
	
	if fields.board then
-- 		id = id + 0
-- 		local boat = boat_data.objects[id]
-- 		print("id ".. id)
-- 		if not boat then
-- 			print("no boat " .. dump(boat) .. " " .. dump(id))
-- 			print(dump(boat_data))
-- 			--enter_boat(boat, player)
-- 		else
-- 			enter_boat(boat, player)
-- 		end
		return
	elseif fields.hold_a then
			-- minetest.show_formspec(player:get_player_name(), "mining:digger_formQ"..self.data.id, get_steel_boat_inv_formspec(self, "a"))
			
	end
	
end)



	
local mdef = {
	hp_max = 1,
	physical = true,
	collisionbox = {-3,-0.5,-3, 3,1.5,3},
	visual = "mesh",
	visual_size = {x=1, y=1},
	mesh = "mining_continuous_miner.x",
	textures = {"default_aspen_wood.png","default_steel_block.png"},
	is_visible = true,
	automatic_rotate = false,
	
	on_step = stepfn,
	
	on_rightclick = rcfn,
	
	get_staticdata = function(self)
		return minetest.serialize(self.data)
	end,
	
	on_activate = function(self, staticdata, dtime_s)
		--self.object:set_armor_groups({immortal = 1})
		if staticdata then
			self.data = minetest.deserialize(staticdata)
			
			if not self.data or not self.data.id then 
				deploy_digger(self)
			end
			print("self.data.id = "..self.data.id)
			print(dump(self))
			mining.objects[self.data.id] = self
		else 
			self.data = {}
			print("digger with no staticdata")
		end
	end,

	
	dig_timer = 0,
	advance = true,
	
	direction = {x=0, y=0, z=1},
	state = "dig",
	last_pos = {x=99999999, y=999999999, z=999999999},
}

minetest.register_entity("mining:digger", mdef)









minetest.register_craftitem("mining:digger", {
	description = "Digger",
	inventory_image = "default_sand.png^[colorize:purple:80",
	wield_image = "boats_tin_wield.png",
	wield_scale = {x = 1, y = 1, z = 1},
	groups = {},
	stack_max = 1,

	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local udef = minetest.registered_nodes[node.name]

		if pointed_thing.type ~= "node" then
			return itemstack
		end
		
		pointed_thing.under.y = pointed_thing.under.y + 1.2
		
		local diggerobj = minetest.add_entity(pointed_thing.under, "mining:digger")
		if diggerobj then
			local digger = diggerobj:get_luaentity()
			digger.empty_carts = 5
			
			local player_name = placer and placer:get_player_name() or ""
			if not (creative and creative.is_enabled_for and
					creative.is_enabled_for(player_name)) then
				itemstack:take_item()
			end
		end
		
		return itemstack
	end,
})








