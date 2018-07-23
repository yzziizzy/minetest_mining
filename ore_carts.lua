





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
	
	local nextp = vector.add(pos, hdir)
	local pn = minetest.get_node(nextp)
	
	if pn.name == "carts:rail" then
		self.object:setvelocity(vector.multiply(self.direction, speed))
	else
-- 		print("checking sides")
		-- check sides
		local left = vector.add(pos, cross) 
		local right = vector.subtract(pos, cross) 
		local ln = minetest.get_node(left)
		local rn = minetest.get_node(right)
		
		if ln.name == rn.name and ln.name == "carts:rail" then
			if math.random(0, 1) == 1 then
				self.direction = cross
				self.object:setvelocity(vector.multiply(self.direction, speed))
			else
				self.direction = vector.multiply(cross, -1)
				self.object:setvelocity(vector.multiply(self.direction, speed))
			end
			
		elseif ln.name == "carts:rail" then
			self.direction = cross
			self.object:setvelocity(vector.multiply(self.direction, speed))
-- 			print("left")
		elseif rn.name == "carts:rail" then
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
	
	on_step = stepfn,
	on_rightclick = function(self)
		self.direction = {
			x = 1,
			y = 0,
			z = 0,
		}
		
	end,
	
	contents = {},
	direction = nil,
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








