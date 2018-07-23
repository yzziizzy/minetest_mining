
local modpath = minetest.get_modpath("mining")
dofile(modpath.. "/ore_carts.lua")



local function stepfn(self, dtime)
	
	local v = {x=.2, y=0, z=0}
	

	
	local pos = self.object:getpos()
	local yaw = self.object:getyaw() or 0
	
	local frontdir = vector.round(vector.normalize(v))
	local cross = {x=frontdir.z, y=0, z= -frontdir.x}
	
	
	-- what is in front of mob?
	local frontpos = vector.add(frontdir, pos)
	
	-- check for stable path forward
	local stable = true
	for x = -1,1 do
		local p = vector.add(frontpos, vector.multiply(cross, x))
		p.y = p.y - 1
		
		local n = minetest.get_node(p)
		if n.name == "air" then
			print("unstable")
			stable = false
			break
		end
		print(dump2(p))
	end
	
	if stable == false then
		self.object:setvelocity({x=0,y=0,z=0})
	else
		self.object:setvelocity(v)
	end
	
	local ll = {}
	for h = 0,3 do
		for w = -4,4 do
			local p = {x=frontpos.x , y = frontpos.y + h, z=frontpos.z + w}
			
			local fnode = minetest.get_node(p)
			
			if fnode.name ~= "air" then
				table.insert(ll, minetest.get_node_drops(fnode.name))
				minetest.set_node(p, {name="air"})
			end
			
		end
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
	collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
	visual = "cube",
	visual_size = {x=1, y=1},
-- 	mesh = "model",
	textures = {"default_aspen_wood.png","default_aspen_wood.png","default_aspen_wood.png","default_aspen_wood.png","default_aspen_wood.png","default_aspen_wood.png"}, -- number of required textures depends on visual
	is_visible = true,
	automatic_rotate = false,
	
	on_step = stepfn,

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








