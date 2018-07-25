


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


local function stepfn(self, dtime)
	
	if self.direction == nil then
		return
	end
	
	local speed = 2
	
	local pos = self.object:getpos()

	
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
				local c = table.remove(self.contents)
				local below = vector.subtract(pos, {x=0,y=1,z=0})
				
				minetest.set_node(below, {name = c})
				minetest.spawn_falling_node(below)
				
				self.last_dump_pos = rpos
			end
		end
	end
	
	
	local nextp = vector.add(pos, hdir)
	local pn = minetest.get_node(nextp)
	
	if minetest.registered_nodes[pn.name].groups.rail ~= nil then
		self.object:setvelocity(vector.multiply(self.direction, speed))
	else
-- 		print("checking sides")
		-- check sides
		local left = vector.add(pos, cross) 
		local right = vector.subtract(pos, cross) 
		local ln = minetest.get_node(left)
		local rn = minetest.get_node(right)
		
		if ln.name == rn.name and minetest.registered_nodes[ln.name].groups.rail ~= nil then
			if math.random(0, 1) == 1 then
				self.direction = cross
				self.object:setvelocity(vector.multiply(self.direction, speed))
			else
				self.direction = vector.multiply(cross, -1)
				self.object:setvelocity(vector.multiply(self.direction, speed))
			end
			
		elseif minetest.registered_nodes[ln.name].groups.rail ~= nil then
			self.direction = cross
			self.object:setvelocity(vector.multiply(self.direction, speed))
-- 			print("left")
		elseif minetest.registered_nodes[rn.name].groups.rail ~= nil then
			self.direction = vector.multiply(cross, -1)
			self.object:setvelocity(vector.multiply(self.direction, speed))
-- 			print("right")
		else
			--stop
			self.object:setpos(pos)
			self.object:setvelocity({x=0, y=0, z=0})
-- 			print("stop")
		end
	end
	
	
	
	
end





local ore_cart_entity = {
	hp_max = 5,
	visual = "mesh",
	mesh = "carts_cart.b3d",
	visual_size = {x=.9, y=.9},
	collisionbox = {-0.45, -0.5, -0.45, 0.45, 0.4, 0.45},
	physical = true,
	textures = {"carts_cart.png"},
	
	on_step = function(self, dtime) 
		return stepfn(self, dtime)
	end,
	
	on_rightclick = function(self)
		self.direction = {
			x = 1,
			y = 0,
			z = 0,
		}
		
	end,
	
	contents = {},
	direction = nil,
	last_dump_pos = {x=999999, y=999999, z=999999},
}

minetest.register_entity("mining:ore_cart", ore_cart_entity)







minetest.register_craftitem("mining:ore_cart", {
	description = "Ore Cart",
	inventory_image = "default_sand.png^[colorize:green:80",
	wield_image = "boats_tin_wield.png",
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








