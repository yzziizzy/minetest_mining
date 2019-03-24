


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


local function printl(str, v)
	print(str .. " ["..v.x..", "..v.y..", "..v.z.."]")
end


local counter = 0

local function stepfn(self, dtime)
	
	--print(" ---- ")
	
	local speed = 2
	
	local pos = self.object:getpos()
	local rpos = vector.round(pos)

	--	printl("pos", pos)
--	printl("rpos", rpos)
	
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
		
		self.object:setvelocity(vector.multiply(self.direction, speed))
		self.last_pos = rpos 
	end
	
	
	local d = vector.distance(self.last_pos, pos)
	
	
	if  d < 1.0 then
		if self.state ~= "stop" then
			self.object:setvelocity(vector.multiply(self.direction, speed))
		end
		
		-- TODO: timer to occasionally fix y-height
		
		return
	end
	self.last_pos = rpos
	print("crossed")
	--self.object:setvelocity({x=0, y=0, z=0})
	
	--if counter == 1 then return end
	--counter = 1
	
	--local ceiln = minetest.get_node({x=math.ceil(pos.x), y=pos.y, z=math.ceil(pos.z)}) 
	--local floorn = minetest.get_node({x=math.floor(pos.x), y=pos.y, z=math.floor(pos.z)}) 
	local cross = {x=self.direction.z, y=0, z= -self.direction.x}
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
	
	
	local nextp = vector.round(vector.add(pos, vector.multiply(self.direction, 1.0)))
	local pn = minetest.get_node(nextp)
	
	if is_rail(pn.name) then
		print("straight")
		self.object:setvelocity(vector.multiply(self.direction, speed))
		
		-- fix sideways errors
		if self.direction.x == 0 then
			pos.x = math.floor(pos.x+0.5)
		end
		if self.direction.z == 0 then
			pos.z = math.floor(pos.z+0.5)
		end
		
		self.object:setpos(pos)
		
		self.state = "straight"
	else
		print("checking sides")
		-- check sides
		local left = vector.add(pos, cross) 
		local right = vector.subtract(pos, cross) 
		local ln = minetest.get_node(left)
		local rn = minetest.get_node(right)
		print("ln "..ln.name)
		print("rn "..rn.name)
		
		self.state = "turning" 
		
		if ln.name == rn.name and is_rail(ln.name) then
			if math.random(0, 1) == 1 then
				self.direction = cross
				self.object:setvelocity(vector.multiply(self.direction, speed))
			else
				self.direction = vector.multiply(cross, -1)
				self.object:setvelocity(vector.multiply(self.direction, speed))
			end
			self.object:setpos(rpos)
			print("random")
		elseif is_rail(ln.name) then
			self.object:setpos(rpos)
			self.direction = cross
			self.object:setvelocity(vector.multiply(self.direction, speed))
			print("left")
		elseif is_rail(rn.name) then
			self.object:setpos(rpos)
			self.direction = vector.multiply(cross, -1)
			self.object:setvelocity(vector.multiply(self.direction, speed))
			print("right")
		else
			--stop
			self.object:setpos(pos)
			self.object:setvelocity({x=0, y=0, z=0})
			print("stop")
			
			self.state = "stop"
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
		{'default:steel_ingot', 'default:cobble',      'default:steel_ingot', },
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot', },
	},
})




minetest.register_node("mining:cart_lift", {
	description = "Cart Lift",
	tiles = { "default_brick.png^[colorize:white:20" },
	is_ground_content = true,
	groups = {cracky=1, level=3 },
	sounds = default.node_sound_stone_defaults(),
})




