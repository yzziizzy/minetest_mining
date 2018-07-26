
local modpath = minetest.get_modpath("mining")
dofile(modpath.. "/ore_carts.lua")



local function stepfn(self, dtime)
	
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
		if self.dig_timer > 1  then 
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
	
	if #ll > 0 then
		local cart = minetest.add_entity(out_rail, "mining:ore_cart")
		if cart then
			local cc = cart:get_luaentity()
			cc.direction = vector.multiply(frontdir, -1)
			cc.contents = ll
		end
	end
	
	
	local all_objects = minetest.get_objects_inside_radius(in_rail, 1.2)
	local carts = {}
	local _,obj
	for _,obj in ipairs(all_objects) do
		if not obj:is_player() then
			if obj:get_luaentity().name == "mining:ore_cart" then
				obj:remove()
			end
		end
	end
		
end






	
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
		
		digger = minetest.add_entity(pointed_thing.under, "mining:digger")
		if digger then
			
			local player_name = placer and placer:get_player_name() or ""
			if not (creative and creative.is_enabled_for and
					creative.is_enabled_for(player_name)) then
				itemstack:take_item()
			end
		end
		
		return itemstack
	end,
})








