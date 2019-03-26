


carts:register_rail("mining:dump_rail", {
	description = "Rail",
	tiles = {
		"carts_rail_straight.png^[colorize:blue:80", "carts_rail_curved.png^[colorize:blue:80",
		"carts_rail_t_junction.png^[colorize:blue:80", "carts_rail_crossing.png^[colorize:blue:80"
	},
	inventory_image = "carts_rail_straight.png",
	wield_image = "carts_rail_straight.png",
	groups = {
		choppy = 2,
		rail = 1,
		connect_to_raillike = minetest.raillike_group("rail")
	},
}, {})


minetest.register_craft({
	output = "mining:dump_rail 3",
	recipe = {
		{"default:steel_ingot", "group:wood", "default:steel_ingot"},
		{"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "group:wood", "default:steel_ingot"},
	}
})



local function is_rail(name) 
	local d = minetest.registered_nodes[name]
	return (d and d.groups.rail ~= nil)
end

local function lift_above(pos) 
	local n = minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z})
	return n and n.name == "mining:cart_lift"
end


local function printl(str, v)
	print(str .. " ["..v.x..", "..v.y..", "..v.z.."]")
end


local node_speeds = {
	["carts:rail"] = 2,
	["mining:cart_lift"] = .5,
	["default"] = 2,
}

local function get_node_speed(name) 
	return node_speeds[name] or node_speeds.default
end



local function find_new_direction(cart, data, pos, rpos)
	
	local npos = vector.add(pos, data.direction)
	
	print("no direction")
	local n
	
	n = minetest.get_node({x=rpos.x + 1, y=rpos.y, z=rpos.z})
	if is_rail(n.name) then
		return {x=1, y=0, z=0}, "moving"
	else
		n = minetest.get_node({x=rpos.x - 1, y=rpos.y, z=rpos.z})
		if is_rail(n.name) then
			return {x=-1, y=0, z=0}, "moving"
		else
			n = minetest.get_node({x=rpos.x, y=rpos.y, z=rpos.z + 1})
			if is_rail(n.name) then
				return {x=0, y=0, z=1}, "moving"
			else
				n = minetest.get_node({x=rpos.x, y=rpos.y, z=rpos.z-1})
				if is_rail(n.name) then
					return {x=0, y=0, z=-1}, "moving"
				else
				
				
					print("checking below")
					--below
					local below = vector.add(nextp, {x=0, y=-1, z=0})
					local bn = minetest.get_node(below)
					local cross = vector.normalize({x=self.direction.z, y=0, z= -self.direction.x})
					
					local bleft = vector.add(vector.add(rpos, cross), {x=0, y=-1, z=0})  
					local bright = vector.add(vector.subtract(rpos, cross), {x=0, y=-1, z=0})
					local bln = minetest.get_node(bleft)
					local brn = minetest.get_node(bright)
				
					print("belowleft: "..bln.name)
					print("belowright: "..brn.name)
				
					if is_rail(bn.name) then
						print("angle down")
						local dir = vector.normalize(vector.add(self.direction, {x=0, y=-1, z=0}))
						return dir, "moving"
						
					elseif is_rail(bln.name) then
						local dir = vector.normalize(vector.add(cross, {x=0, y=-1, z=0}))
						return dir, "moving"
						
					elseif is_rail(brn.name) then
						local dir = vector.normalize(vector.add(vector.multiply(cross, -1), {x=0, y=-1, z=0}))
						return dir, "moving"
					else
						
						-- check for lifting
						local apos = vector.add(pos, {x=0,y=1,z=0})
						local anode = minetest.get_node(apos)
						if anode.name == "mining:cart:lift" then
							return {x=0,y=1,z=0}, "moving"
						end
						
						
						print("isolated cart")
						return nil, "stop"
					end
				
				end
			end
		end 
	end
	
	
	
	
end



local operations = {
	["carts:rail"] = function(cart, data, pos, rpos) 
		-- see if we can just keep going
		local npos = vector.add(pos, data.direction)
		local node = minetest.get_node(npos)
		if is_rail(node.name) then
			-- good, keep going
			return
		end
		
		local dir, state = find_new_direction(cart, data, pos, rpos)
		data.direction = dir
		data.state = state
		data.speed = get_node_speed(node.name)
		
		if state == "moving" then
			self.object:setvelocity(vector.multiply(dir, data.speed))
			-- TODO: fix positions not in direction of travel
		end
		
	end,
	
	["mining:cart_lift"] = function(cart, data, pos, rpos) -- go up, then go out
		local upos = vector.add(pos, {x=0,y=1,z=0})
		local unode = minetest.get_node(upos)
		if unode.name == "mining:cart_lift" then
			-- keep going up
			return
		end
		
		-- look for new direction
		local dir, state = find_new_direction(cart, data, pos, rpos)
		data.direction = dir
		data.state = state
		data.speed = get_node_speed(node.name)
		
		if state == "moving" then
			self.object:setvelocity(vector.multiply(dir, data.speed))
			-- TODO: fix positions not in direction of travel
		end
	
	end,
	
	["mining:rail_switch"] = function(cart, data, pos, rpos) -- internal switching state
	
	
	end,

	["mining:rail_multiplexer"] = function(cart, data, pos, rpos) -- alternate exits
	
	
	end,

	["mining:dump_rail"] = function(cart, data, pos, rpos) -- alternate exits
		if #data.contents == 0 then
			return
		end
		
		if not vector.equals(rpos, data.last_dump_pos) then
			local below = vector.subtract(rpos, {x=0,y=1,z=0})
			local bn = minetest.get_node(below)
			
			if bn.name == "air" then
				local c = table.remove(data.contents)
				minetest.set_node(below, {name = c})
				minetest.spawn_falling_node(below)
				
				cart.object:set_animation({x = 1, y = 15}, 10, 0, false)
				
				data.last_dump_pos = rpos
			end
		end
	

	end,

	["carts:brake_rail"] = function(cart, data, pos, rpos) -- pause until restarted
		data.state = "paused"
		cart.object:setvelocity({x=0,y=0,z=0})
		cart.object:setpos(rpos)
		
		return data.direction, "paused"
	end,

	["default"] = function() -- unknown node underneath
	
	
	end,

}










-- obsolete
local function check_new_direction(self, rpos)

	if self.direction == nil or self.direction.x == nil then
		print("no direction")
		local n
		
		n = minetest.get_node({x=rpos.x + 1, y=rpos.y, z=rpos.z})
		if is_rail(n.name) then
			self.direction = {x=1, y=0, z=0}
		else
			n = minetest.get_node({x=rpos.x - 1, y=rpos.y, z=rpos.z})
			if is_rail(n.name) then
				self.direction = {x=-1, y=0, z=0}
			else
				n = minetest.get_node({x=rpos.x, y=rpos.y, z=rpos.z + 1})
				if is_rail(n.name) then
					self.direction = {x=0, y=0, z=1}
				else
					n = minetest.get_node({x=rpos.x, y=rpos.y, z=rpos.z-1})
					if is_rail(n.name) then
						self.direction = {x=0, y=0, z=-1}
					else
						print("isolated cart")
						return
					end
				end
			end 
		end
		
		self.object:setvelocity(vector.multiply(self.direction, self.speed))
		self.last_pos = rpos 
	end
end




-- for debugging
local counter = 0


local function stepfn(self, dtime)
	local pos = self.object:getpos()
	local data = self.data
	
	if data == nil then
		return
	end
	
	local d = vector.distance(data.last_pos, pos)

	local rpos = vector.round(pos)

	
	if  d > 1.0 then
		-- crossed block lines
		
		local posnode = minetest.get_node(pos)
		
		local fn = operations[posnode.name] or operations.default
		
		fn(self, data, pos, rpos)
		
	end
	
	
	
	
	if 1==1 then return end
	
	--- old algorithm
	
	
	--print(" ---- ")
	
	if self.speed == nil then
		self.speed = 2
	end
	
	local pos = self.object:getpos()
	local rpos = vector.round(pos)

	--	printl("pos", pos)
--	printl("rpos", rpos)
	
	check_new_direction(self, rpos)
	
	
	local d = vector.distance(self.last_pos, pos)
	
	if self.state == "lifting" then
		self.speed = .5
	elseif self.state ~= "stop" then
		self.speed = 2
	end
		
	if  d < 1.0 then
		if self.state ~= "stop" then
			self.object:setvelocity(vector.multiply(self.direction, self.speed))
		end
		-- TODO: timer to occasionally fix y-height
		
		return
	end
	self.last_pos = rpos
-- 	print("crossed")
	--self.object:setvelocity({x=0, y=0, z=0})
	
	--if counter == 1 then return end
	--counter = 1
	
	--local ceiln = minetest.get_node({x=math.ceil(pos.x), y=pos.y, z=math.ceil(pos.z)}) 
	--local floorn = minetest.get_node({x=math.floor(pos.x), y=pos.y, z=math.floor(pos.z)}) 
	local cross = vector.normalize({x=self.direction.z, y=0, z= -self.direction.x})
	local hdir = vector.multiply(self.direction, .5)
	
	
	-- check for dumping contents
	if #self.contents > 0 then
		local rpos = vector.round(pos)
		
		if not vector.equals(rpos, self.last_dump_pos) then
			local posnode = minetest.get_node(pos)
			
			if posnode.name == "mining:dump_rail" then
				local below = vector.subtract(pos, {x=0,y=1,z=0})
				local bn = minetest.get_node(below)
				
				if bn.name == "air" then
					local c = table.remove(self.contents)
					minetest.set_node(below, {name = c})
					minetest.spawn_falling_node(below)
					
					self.object:set_animation({x = 1, y = 15}, 10, 0, false)
					
					self.last_dump_pos = rpos
				end
			end
		end
	end
	
	
	local nextp = vector.round(
		vector.add(pos, 
			vector.multiply(
-- 				vector.normalize({x=self.direction.x, y=0, z=self.direction.z}), 
				self.direction, 
				1.0)
		)
	)
	local pn = minetest.get_node(nextp)
	
	if is_rail(pn.name) then
-- 		print("straight")
		self.object:setvelocity(vector.multiply(self.direction, self.speed))
		
		-- fix sideways errors
		if self.direction.x == 0 then
			pos.x = math.floor(pos.x+0.5)
		end
		if self.direction.z == 0 then
			pos.z = math.floor(pos.z+0.5)
		end
		
		self.object:setpos(pos)
		
		self.state = "straight"
	elseif self.state == "lifting" then
		if lift_above(rpos) then
			-- keep lifting
			print("still lifting")
		else
			print("looking for new direction at end of lift")
			self.direction = nil
			check_new_direction(self, rpos)
			
		end
	else
-- 		print("checking sides")
		-- check sides
-- 		printl("pos", pos)
		local left = vector.add(pos, cross) 
		local right = vector.subtract(pos, cross) 
-- 		printl("left", left )
-- 		printl("right", right )
		local ln = minetest.get_node(left)
		local rn = minetest.get_node(right)
-- 		print("ln "..ln.name)
-- 		print("rn "..rn.name)
		

		
		--front
		local front = vector.add(rpos, vector.normalize({x=self.direction.x, y=0, z=self.direction.z}))
		local fn = minetest.get_node(front)
		
		--self.state = "turning" 
		
		if ln.name == rn.name and is_rail(ln.name) then
			if math.random(0, 1) == 1 then
				self.direction = cross
				self.object:setvelocity(vector.multiply(self.direction, self.speed))
			else
				self.direction = vector.multiply(cross, -1)
				self.object:setvelocity(vector.multiply(self.direction, self.speed))
			end
			self.object:setpos(rpos)
			print("random")
		elseif is_rail(ln.name) then
			self.object:setpos(rpos)
			self.direction = cross
			self.object:setvelocity(vector.multiply(self.direction, self.speed))
			print("left")
		elseif is_rail(rn.name) then
			self.object:setpos(rpos)
			self.direction = vector.multiply(cross, -1)
			self.object:setvelocity(vector.multiply(self.direction, self.speed))
			print("right")
		elseif is_rail(fn.name) then
			self.object:setpos(rpos)
			self.direction = vector.normalize({x=self.direction.x, y=0, z=self.direction.z})
			self.object:setvelocity(vector.multiply(self.direction, self.speed))
			
		elseif lift_above(rpos) then
			self.object:setpos(rpos)
			self.direction = {x=0, y=1, z=0}
			self.speed = .5
			self.object:setvelocity(vector.multiply({x=0, y=1, z=0}, self.speed))
			
			self.state = "lifting"
			print("lifting")
		else
			print("checking below")
			--below
			local below = vector.add(nextp, {x=0, y=-1, z=0})
			local bn = minetest.get_node(below)
			
			local bleft = vector.add(vector.add(rpos, cross), {x=0, y=-1, z=0})  
			local bright = vector.add(vector.subtract(rpos, cross), {x=0, y=-1, z=0})
			local bln = minetest.get_node(bleft)
			local brn = minetest.get_node(bright)
		
			print("belowleft: "..bln.name)
			print("belowright: "..brn.name)
		
			if is_rail(bn.name) then
				print("angle down")
				
				local dir = vector.normalize(vector.add(self.direction, {x=0, y=-1, z=0}))
				self.direction = dir
				printl("dir", dir)
				self.object:setvelocity(vector.multiply(dir, self.speed))
				
			elseif is_rail(bln.name) then
				self.object:setpos(rpos)
				
				local dir = vector.normalize(
					vector.add(cross, {x=0, y=-1, z=0}))
				self.direction = dir
				self.object:setvelocity(vector.multiply(self.direction, self.speed))
				print("down left")
			elseif is_rail(brn.name) then
				self.object:setpos(rpos)
				local dir = vector.normalize(
					vector.add(vector.multiply(cross, -1), 
						{x=0, y=-1, z=0}))
				self.object:setvelocity(vector.multiply(self.direction, self.speed))
				print("down right")
				
			else
				--stop
				self.object:setpos(pos)
				self.object:setvelocity({x=0, y=0, z=0})
				print("stop")
				
				self.state = "stop"
			
			end
		end
	end
	
	

	
end


local ore_cart_defaults = {
	contents = {},
	direction = {},
	last_dump_pos = {x=999999, y=999999, z=999999},
	last_pos = {x=999999, y=999999, z=999999},
	state = "straight",
}



local ore_cart_entity = {
 	hp_max = 2,
	visual = "mesh",
	mesh = "mining_cart.x",
	visual_size = {x=1, y=1},
	collisionbox = {-0.45, -0.5, -0.45, 0.45, 0.4, 0.45},
	physical = true,
	textures = {"mining_cart.png", "mining_cart.png"},
		
	on_step = function(self, dtime) 
		return stepfn(self, dtime)
	end,
	
	on_punch = function(self, puncher)
		local look = vector.round(puncher:get_look_dir())
	
		self.direction = look
	end,
	
	get_staticdata = function(self)
		local temp = {}
		for k,_ in pairs(ore_cart_defaults) do
			temp[k] = self[k]
		end
		print(dump2(temp))
		return minetest.serialize(temp)
	end,
	
	on_activate = function(self, staticdata)
		
-- 		self.object:set_armor_groups({immortal = 1})
		print(dump2(staticdata))
		if staticdata then
			local temp = minetest.deserialize(staticdata)
			print(dump2(temp))
			if temp ~= nil then
				for k,v in pairs(temp) do
					if v ~= nil then
						self[k] = v
					end
				end
			end
		end
	end,
		
	push = function(self) 
		print("ore cart push called")
		
	end,

}

for k,v in pairs(ore_cart_defaults) do
	ore_cart_entity[k] = v
end

minetest.register_entity("mining:ore_cart", ore_cart_entity)







minetest.register_craftitem("mining:ore_cart", {
	description = "Ore Cart",
	inventory_image = "default_sand.png^[colorize:green:80",
-- 	wield_image = "boats_tin_wield.png",
	wield_scale = {x = 1, y = 1, z = 1},
	groups = {},
	stack_max = 1,

	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local udef = minetest.registered_nodes[node.name]
		
		if udef.name ~= "carts:rail" then
			return
		end
		
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		
		pointed_thing.under.y = pointed_thing.under.y 
		
		local cart = minetest.add_entity(pointed_thing.under, "mining:ore_cart")
		if cart then
			local player_name = placer and placer:get_player_name() or ""
			if not (creative and creative.is_enabled_for and
					creative.is_enabled_for(player_name)) then
				itemstack:take_item()
			end
		end
		
		return itemstack
	end,
})



minetest.register_craft({
	output = "mining:ore_cart",
	recipe = {
		{'',                    '',                    '',                    },
		{'group:wood',          'default:cobble',      'group:wood',          },
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot', },
	},
})




minetest.register_node("mining:cart_lift", {
	description = "Cart Lift",
	tiles = { "default_bronze_block.png" },
	is_ground_content = true,
	groups = {cracky=1, level=3 },
	sounds = default.node_sound_stone_defaults(),
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.55, -0.5, -0.55, -0.51, 0.5, -0.51},
			{-0.55, -0.5,  0.55, -0.51, 0.5,  0.51},
			{ 0.55, -0.5, -0.55,  0.51, 0.5, -0.51},
			{ 0.55, -0.5,  0.55,  0.51, 0.5,  0.51},
		},
-- 		fixed = {
-- 			{-0.5, -0.5, -0.5, -0.45, 0.5, -0.45},
-- 			{-0.5, -0.5,  0.5, -0.45, 0.5,  0.45},
-- 			{ 0.5, -0.5, -0.5,  0.45, 0.5, -0.45},
-- 			{ 0.5, -0.5,  0.5,  0.45, 0.5,  0.45},
-- 		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
	},
})



minetest.register_craft({
	output = "mining:cart_lift",
	recipe = {
		{'default:bronze_ingot', '', 'default:bronze_ingot' },
		{'',              'mining:ore_cart',      ''},
		{'default:bronze_ingot', '', 'default:bronze_ingot' },
	},
})



