-- The Group class is responsible for object management.
-- A common usage is to create different groups for different "layers" of behavior in the game:
--[[
Game = Object:extend()
Game:implement(State)
function Game:on_enter()
  self.main = Group():set_as_physics_world(192)
  self.effects = Group()
  self.floor = Group()
  self.ui = Group():no_camera()
end


function Game:update(dt)
  self.main:update(dt)
  self.floor:update(dt)
  self.effects:update(dt)
  self.ui:update(dt)
end


function Game:draw()
  self.floor:draw()
  self.main:sort_by_y()
  self.main:draw()
  self.effects:draw()
  self.ui:draw()
end
]]--

-- This is a simple example where you have four groups, each for a different purpose.
-- The main group is where all gameplay objects are and thus the only one that's using the physics world (box2d).
-- If you need an object to collide with another physically then they have to use the same physics world, and thus also the same group.
-- The effects and floor groups are purely visual, one for drawing things on the floor (it's a top-down-ish 2.5D game), like shadows, and the other for drawing visual effects on top of everything else.
-- As you can see in the draw function, floor is drawn first and effects is drawn after all gameplay objects.
-- These three groups above also all use the game's main camera instance as their targets since we want gameplay objects, floor and visual effects to be drawn according to the camera's transform.
-- Finally, the UI group is the one that doesn't have a camera attached to it because we want its objects to be drawn in fixed locations on the screen.
-- And this group is also drawn last because generally UI elements go on top of literally everything else.
Group = Object:extend()
function Group:init()
  self.t = Trigger()
  self.camera = camera
  self.objects = {}
  self.objects.by_id = {}
  self.objects.by_class = {}
  self.cells = {}
  self.cell_size = 64
  return self
end


function Group:update(dt)
  Profiler:start("group_trigger_update")
  self.t:update(dt)
  Profiler:finish("group_trigger_update")
  
  Profiler:start("group_object_updates")
  
  -- Count objects by type for better analysis
  local object_counts = {}
  local unknown_objects = {}
  for _, object in ipairs(self.objects) do
    local metatable = getmetatable(object)
    local class_name = "Unknown"
    
    if metatable then
      if metatable.__name then
        class_name = metatable.__name
      elseif metatable.__index and metatable.__index.__name then
        class_name = metatable.__index.__name
      elseif object.class_name then
        class_name = object.class_name
      elseif object.type then
        class_name = object.type
      elseif object.character then
        class_name = "Troop_" .. object.character
      else
        -- Identify common object patterns
        if object.steerable and object.type then class_name = "Enemy_" .. object.type
        elseif object.steerable and object.character then class_name = "Troop_" .. object.character
        elseif object.current_hp then class_name = "HPBar"
        elseif object.animation then class_name = "AnimatedObject"
        elseif object.spell_name then class_name = "Spell_" .. object.spell_name
        elseif object.area_spell then class_name = "AreaSpell_" .. (object.spell_type or "unknown")
        elseif object.projectile then class_name = "Projectile_" .. (object.projectile_type or "unknown")
        elseif object.effect then class_name = "Effect_" .. (object.effect_type or "unknown")
        elseif object.buff or object.debuff then class_name = "StatusEffect"
        elseif object.damage_instance then class_name = "DamageInstance"
        elseif object.visual_effect then class_name = "VisualEffect"
        elseif object.shape and object.body then class_name = "PhysicsObject"
        elseif object.shape then class_name = "ShapeObject"
        elseif object.t then class_name = "GameObject"
        else 
          -- Track unknown for debugging
          table.insert(unknown_objects, {
            props = {steerable = object.steerable, character = object.character, type = object.type, 
                    current_hp = object.current_hp, animation = object.animation, spell_name = object.spell_name,
                    shape = object.shape and true, body = object.body and true, t = object.t and true},
            metatable = tostring(metatable):sub(-8)
          })
        end
      end
    end
    
    object_counts[class_name] = (object_counts[class_name] or 0) + 1
  end
  
  -- Debug unknown objects (only first few)
  if #unknown_objects > 0 and #unknown_objects <= 3 then
    for i, obj in ipairs(unknown_objects) do
      print("Unknown object " .. i .. " metatable:" .. obj.metatable .. " props:", table.tostring(obj.props, 1))
    end
  end
  
  -- Log object counts for major types (only when there are many)
  for class_name, count in pairs(object_counts) do
    if count > 20 then  -- Only log if there are many objects of this type
      local profile_name = "count_" .. class_name
      if not Profiler.system_totals[profile_name] then
        Profiler.system_totals[profile_name] = {total_time = 0, calls = 0, max_time = 0, object_count = 0}
      end
      Profiler.system_totals[profile_name].object_count = count
    end
  end
  
  for _, object in ipairs(self.objects) do
    -- Profile by object class for detailed breakdown
    local class_name = "Unknown"
    local metatable = getmetatable(object)
    
    if metatable then
      if metatable.__name then
        class_name = metatable.__name
      elseif metatable.__index and metatable.__index.__name then
        class_name = metatable.__index.__name
      elseif object.class_name then
        class_name = object.class_name
      elseif object.type then
        class_name = object.type
      elseif object.character then
        class_name = "Troop_" .. object.character
      else
        -- Try to identify by properties
        if object.steerable then class_name = "Steerable" end
        if object.physics then class_name = class_name .. "Physics" end
        if object.shape then class_name = class_name .. "Shape" end
        if class_name == "Unknown" then
          class_name = "Unknown_" .. tostring(metatable):sub(-6) -- Last 6 chars of metatable address
        end
      end
    end
    
    local profile_name = "update_" .. class_name
    Profiler:start(profile_name)
    
    if object.force_update then
      object:update(1/refresh_rate)
    else
      object:update(dt)
    end
    
    Profiler:finish(profile_name)
  end
  Profiler:finish("group_object_updates")
  
  if self.world then 
    Profiler:start("physics")
    self.world:update(dt) 
    Profiler:finish("physics")
  end

  Profiler:start("group_spatial_indexing")
  self.cells = {}
  for _, object in ipairs(self.objects) do
    local cx, cy = math.floor(object.x/self.cell_size), math.floor(object.y/self.cell_size)
    if tostring(cx) == tostring(0/0) or tostring(cy) == tostring(0/0) then
    else
      if not self.cells[cx] then self.cells[cx] = {} end
      if not self.cells[cx][cy] then self.cells[cx][cy] = {} end
      table.insert(self.cells[cx][cy], object)
    end
  end
  Profiler:finish("group_spatial_indexing")

  Profiler:start("group_dead_object_cleanup")
  for i = #self.objects, 1, -1 do
    if self.objects[i].dead then
      if self.objects[i].onDeath then self.objects[i]:onDeath() end
      if self.objects[i].destroy then self.objects[i]:destroy() end
      self.objects.by_id[self.objects[i].id] = nil
      table.delete(self.objects.by_class[getmetatable(self.objects[i])], function(v) return v.id == self.objects[i].id end)
      table.remove(self.objects, i)
    end
  end
  Profiler:finish("group_dead_object_cleanup")
end


-- scroll_factor_x and scroll_factor_y can be used for parallaxing, they should be values between 0 and 1
-- The closer to 0, the more of a parallaxing effect there will be.
--supports z_index and draw to custom canvas
function Group:draw(scroll_factor_x, scroll_factor_y)
  if self.camera then self.camera:attach(scroll_factor_x, scroll_factor_y) end
  local z_indexed_objects = {}

  Profiler:start("group_normal_objects")
  for _, object in ipairs(self.objects) do
    if not object.hidden then
      if object.z_index then
        --separate z_indexed objects
        if not z_indexed_objects[object.z_index] then z_indexed_objects[object.z_index] = {} end
        table.insert(z_indexed_objects[object.z_index], object)
      else
        --draw normal objects
        if self.custom_draw_list then
          table.insert(self.custom_draw_list, function()
            object:draw()
          end)
        else
          object:draw()
        end
      end
    end
  end
  Profiler:finish("group_normal_objects")
  
  Profiler:start("group_z_indexed_objects")
  for k, objects in pairs(z_indexed_objects) do
    for _, object in ipairs(objects) do
      --draw z_indexed objects after the normal objects
      if self.custom_draw_list then
        table.insert(self.custom_draw_list, function()
          object:draw()
        end)
      else
        object:draw()
      end
    end
  end
  Profiler:finish("group_z_indexed_objects")

  if self.camera then self.camera:detach() end
end

function Group:draw_floor_effects()
  if #self.objects == 0 then return end
  
  Profiler:start("floor_effects_collect")
  -- Collect all floor effects
  local floor_effects = {}

  for _, object in ipairs(self.objects) do
    if object.floor_effect and not object.dead then
      if not floor_effects[object.floor_effect] then 
        floor_effects[object.floor_effect] = {}
      end
      table.insert(floor_effects[object.floor_effect], object)
    end
  end
  Profiler:finish("floor_effects_collect")

  Profiler:start("floor_effects_render")
  DrawUtils.draw_floor_effects(floor_effects)
  Profiler:finish("floor_effects_render")
end

function Group:set_custom_draw_list(draw_list)
  self.custom_draw_list = draw_list
end


-- Draws only objects within the indexed range
-- group:draw_range(1, 3) -> draws only 1st, 2nd and 3rd objects in this group
function Group:draw_range(i, j, scroll_factor_x, scroll_factor_y)
  if self.camera then self.camera:attach(scroll_factor_x, scroll_factor_y) end
    for k = i, j do
      if not self.objects[k].hidden then
        self.objects[k]:draw()
      end
    end
  if self.camera then self.camera:detach() end
end


-- Draws only objects of a certain class
-- group:draw_class(Solid) -> draws only objects of the Solid class
function Group:draw_class(class, scroll_factor_x, scroll_factor_y)
  if self.camera then self.camera:attach(scroll_factor_x, scroll_factor_y) end
    for _, object in ipairs(self.objects) do
      if object:is(class) and not object.hidden then
        object:draw()
      end
    end
  if self.camera then self.camera:detach() end
end


-- Draws all objects except those of specified classes
-- group:draw_all_except({Solid, SolidGeometry}) -> draws all objects except those of the Solid and SolidGeometry classes
function Group:draw_all_except(classes, scroll_factor_x, scroll_factor_y)
  if self.camera then self.camera:attach(scroll_factor_x, scroll_factor_y) end
    for _, object in ipairs(self.objects) do
      if not table.any(classes, function(v) return object:is(v) end) and not object.hidden then
        object:draw()
      end
    end
  if self.camera then self.camera:detach() end
end


-- Sets this group as one without a camera, useful for things like UIs
function Group:no_camera()
  self.camera = nil
  return self
end


-- Sorts all objects in this group by their y position
-- This is useful for top-down 2.5D games so that objects further up on the screen are drawn first and look like they're further away from the camera
-- Objects can additionally have a .y_sort_offset attribute which gets added to this function's calculations
-- This attribute is useful for objects that are longer vertically and need some adjusting otherwise the point at which they get drawn behind looks off
function Group:sort_by_y()
  table.sort(self.objects, function(a, b) return (a.y + (a.y_sort_offset or 0)) < (b.y + (b.y_sort_offset or 0)) end)
end


-- Returns the mouse position based on the camera used by this group
-- mx, my = group:get_mouse_position() 
function Group:get_mouse_position()
  if self.camera then
    return self.camera.mouse.x, self.camera.mouse.y
  else
    local mx, my = love.mouse.getPosition()
    return mx/sx, my/sy
  end
end


function Group:destroy()
  for _, object in ipairs(self.objects) do if object.destroy then object:destroy() end end
  self.objects = {}
  self.objects.by_id = {}
  self.objects.by_class = {}
  if self.world then
    self.world:destroy()
    self.world = nil
  end
  return self
end


-- Adds an existing object to the group
-- player = Player{x = 160, y = 80}
-- group:add(player)
-- Creates an object and automatically add it to the group
-- player = Player{group = group, x = 160, y = 80}
-- The object has its .group attribute set to this group, and has a random .id set if it doesn't already have one
function Group:add(object)
  local class = getmetatable(object)
  object.group = self

  if not object.id then object.id = random:uid() end
  self.objects.by_id[object.id] = object
  if not self.objects.by_class[class] then self.objects.by_class[class] = {} end
  table.insert(self.objects.by_class[class], object)
  table.insert(self.objects, object)
  return object
end


-- Returns an object by its unique id
-- group:get_object_by_id(id) -> the object
function Group:get_object_by_id(id)
  return self.objects.by_id[id]
end


-- Returns the first object found after searching for it by property, the property value must be unique among all objects
-- group:get_object_by_property('special_id', 347762) -> the object
function Group:get_object_by_property(key, value)
  for _, object in ipairs(self.objects) do
    if object[key] == value then
      return object
    end
  end
end


-- Returns an object after searching for it by properties with all of them matching, the property value match must be unique among all objects
-- group:get_object_by_properties({'special_id_1', 'special_id_2'}, {347762, 32452}) -> the object
function Group:get_object_by_properties(keys, values)
  for _, object in ipairs(self.objects) do
    local this_is_the_object = true
    for i = 1, #keys do
      if object[keys[i]] ~= values[i] then
        this_is_the_object = false
      end
    end
    if this_is_the_object then
      return object
    end
  end
end


-- Returns all objects of a specific class
-- group:get_objects_by_class(Star) -> all objects of class Star in a table
function Group:get_objects_by_class(class)
  Profiler:start("find_get_objects_by_class")
  local result
  if not self.objects.by_class[class] then 
    result = {}
  else 
    result = table.shallow_copy(self.objects.by_class[class]) 
  end
  Profiler:finish("find_get_objects_by_class")
  return result
end


-- Returns all objects of the specified classes
-- group:get_objects_by_classes({Star, Enemy, Projectile}) -> all objects of class Star, Enemy or Projectile in a table
function Group:get_objects_by_classes(class_list)
  local objects = {}
  for _, class in ipairs(class_list) do table.insert(objects, self:get_objects_by_class(class)) end
  return table.flatten(objects, true)
end


-- Returns all objects inside the shape, using its .x, .y attributes as the center and its .w, .h attributes as its bounding size.
-- If object_types is passed in then it only returns object of those classes.
-- The bounding size is used to select objects quickly and roughly, and then more specific and expensive collision methods are run on the objects returned from that selection.
-- group:get_objects_in_shape(Rectangle(player.x, player.y, 100, 100, player.r), {Enemy1, Enemy2}) -> all Enemy1 and Enemy2 instances in a 100x100 rotated rectangle around the player
-- group:get_objects_in_shape(Rectangle(player.x, player.y, 100, 100, player.r), {Enemy1, Enemy2}, {object_1, object_2}) -> same as above except excluding object instances object_1 and object_2
function Group:get_objects_in_shape(shape, object_types, exclude_list)
  Profiler:start("find_get_objects_in_shape")
  local out = {}
  local exclude_list = exclude_list or {}
  
  Profiler:start("find_spatial_cell_lookup")
  local cx1, cy1 = math.floor((shape.x-shape.w)/self.cell_size), math.floor((shape.y-shape.h)/self.cell_size)
  local cx2, cy2 = math.floor((shape.x+shape.w)/self.cell_size), math.floor((shape.y+shape.h)/self.cell_size)
  Profiler:finish("find_spatial_cell_lookup")
  
  Profiler:start("find_collision_detection")
  local collision_checks = 0
  local shape_type = type(shape) == "table" and (shape.type or "unknown_shape") or "primitive_shape"
  
  for i = cx1, cx2 do
    for j = cy1, cy2 do
      local cx, cy = i, j
      if self.cells[cx] then
        local cell_objects = self.cells[cx][cy]
        if cell_objects then
          for _, object in ipairs(cell_objects) do
            if object.fully_onscreen then
              if object_types then
                if not table.any(exclude_list, function(v) return v.id == object.id end) then
                  if table.any(object_types, function(v) return object:is(v) end) and object.shape then
                    collision_checks = collision_checks + 1
                    Profiler:start("collision_shape_check_" .. shape_type)
                    if object.shape:is_colliding_with_shape(shape) then
                      table.insert(out, object)
                    end
                    Profiler:finish("collision_shape_check_" .. shape_type)
                  end
                end
              else
                if object.shape then
                  collision_checks = collision_checks + 1
                  Profiler:start("collision_shape_check_" .. shape_type)
                  if object:is_colliding_with_shape(shape) then
                    table.insert(out, object)
                  end
                  Profiler:finish("collision_shape_check_" .. shape_type)
                end
              end
            end
          end
        end
      end
    end
  end
  
  -- Track collision check intensity
  if collision_checks > 50 then
    local profile_name = "high_collision_checks_" .. shape_type
    if not Profiler.system_totals[profile_name] then
      Profiler.system_totals[profile_name] = {total_time = 0, calls = 0, max_time = 0, collision_checks = 0}
    end
    Profiler.system_totals[profile_name].collision_checks = collision_checks
  end
  
  Profiler:finish("find_collision_detection")
  
  Profiler:finish("find_get_objects_in_shape")
  return out
end

function Group:get_closest_object_by_class(object, object_types, exclude_list)
  return self:get_closest_object(object, function(o) 
    local is_valid_type = table.any(object_types, function(v) return o:is(v) end)
    local is_not_excluded = not exclude_list or not table.any(exclude_list, function(v) return v.id == o.id end)
    local is_fully_onscreen = o.fully_onscreen
    return is_valid_type and is_not_excluded and is_fully_onscreen
  end)
end

function Group:get_random_object_by_class(object_types)
  local objects = self:get_objects_by_classes(object_types)
  return table.random(objects)
end


-- Returns the closest object in this group to the object passed in
-- Optionally also pass in a function which will only allow objects that pass its test to be considered in the calculations
-- group:get_closest_object(player) -> closest object to the player, if the player is in this group then this object will be the player itself
-- group:get_closest_object(player, function(o) return o.id ~= player.id end) -> closest object to the player that isn't the player
function Group:get_closest_object(object, select_function)
  Profiler:start("find_get_closest_object")
  if not select_function then select_function = function(o) return true end end
  local min_distance, min_index = 100000, 0
  for i, o in ipairs(self.objects) do
    if select_function(o) then
      local d = math.distance(o.x, o.y, object.x, object.y)
      if d < min_distance then
        min_distance = d
        min_index = i
      end
    end
  end
  Profiler:finish("find_get_closest_object")
  return self.objects[min_index]
end

function Group:get_random_close_object(object, object_types, exclude_list, max_range_from_self, distance_tolerance, percentage_tolerance)
  Profiler:start("find_get_random_close_object")
  exclude_list = exclude_list or {}
  distance_tolerance = distance_tolerance or 20
  percentage_tolerance = percentage_tolerance or 20

  -- First, get all potential candidates based on their class and exclude list.
  -- This pre-filters the objects, making the distance check more efficient.
  local candidates = self:get_objects_by_classes(object_types)

  -- Filter out any objects that are in the exclude list.
  if #exclude_list > 0 then
    candidates = table.filter(candidates, function(o) 
      return not table.any(exclude_list, function(v) return v.id == o.id end)
    end)
  end
  
  -- If there are no candidates after initial filtering, return nil.
  if #candidates == 0 then
      Profiler:finish("find_get_random_close_object")
      return nil
  end

  local min_distance = math.huge

  -- PASS 1: Find the absolute closest object and its distance
  for _, o in ipairs(candidates) do
      local d = math.distance(o.x, o.y, object.x, object.y)
      if d < min_distance then
          min_distance = d
      end
  end

  -- Determine the tolerance threshold
  local max_distance_option = min_distance + distance_tolerance
  local max_percentage_option = min_distance * (percentage_tolerance / 100)

  local max_distance_for_candidates = math.min(max_distance_option, max_percentage_option)
  if max_range_from_self then
    max_distance_for_candidates = math.min(max_distance_for_candidates, max_range_from_self)
  end

  local final_candidates = {}
  -- PASS 2: Find all other objects that are within the tolerance
  for _, o in ipairs(candidates) do
      local d = math.distance(o.x, o.y, object.x, object.y)
      if d <= max_distance_for_candidates then
          table.insert(final_candidates, o)
      end
  end

  -- Randomly select and return a target from the final candidates list
  local result = nil
  if #final_candidates > 0 then
      result = table.random(final_candidates)
  end
  
  Profiler:finish("find_get_random_close_object")
  return result
end
  


-- Sets this group as a physics box2d world
-- This means that objects inserted here can also be initialized as physics objects (see the gameobject file for more on this)
-- group:set_as_physics_world(192, 0, 400) -> a common platformer setup with vertical downward gravity
-- group:set_as_physics_world(192) -> a common setup for most non-platformer games
-- If your game takes place in smaller world coordinates (i.e. you set game_width and game_height to 320x240 or something) then you'll want smaller meter values, like 32 instead of 192
-- Read more on meter values for box2d worlds here: https://love2d.org/wiki/love.physics.setMeter
-- The last argument, tags, is a list of strings corresponding to collision tags that will be assigned to different objects, for instance:
-- group:set_as_physics_world(192, 0, 0, {'player', 'enemy', 'projectile', 'ghost'})
-- As different physics objects have different collision behaviors in regards to one another, the tags created here will facilitate the delineation of those differences.
function Group:set_as_physics_world(meter, xg, yg, tags)
  love.physics.setMeter(meter or 192)
  self.tags = table.unify(table.push(tags, 'solid'))
  self.collision_tags = {}
  self.trigger_tags = {}
  for i, tag in ipairs(self.tags) do
    self.collision_tags[tag] = {category = i, masks = {}}
    self.trigger_tags[tag] = {category = i, triggers = {}}
  end

  self.world = love.physics.newWorld(xg or 0, yg or 0)
  self.world:setCallbacks(
    function(fa, fb, c) --begincontact
      local oa, ob = self:get_object_by_id(fa:getUserData()), self:get_object_by_id(fb:getUserData())
      if fa:isSensor() or fb:isSensor() then
        if fa:isSensor() then if oa.on_trigger_enter then oa:on_trigger_enter(ob, c) end end
        if fb:isSensor() then if ob.on_trigger_enter then ob:on_trigger_enter(oa, c) end end
      else
        if oa.on_collision_enter then oa:on_collision_enter(ob, c) end
        if ob.on_collision_enter then ob:on_collision_enter(oa, c) end
      end
    end,
    function(fa, fb, c) --endcontact
      local oa, ob = self:get_object_by_id(fa:getUserData()), self:get_object_by_id(fb:getUserData())
      if fa:isSensor() or fb:isSensor() then
        if fa:isSensor() then if oa.on_trigger_exit then oa:on_trigger_exit(ob, c) end end
        if fb:isSensor() then if ob.on_trigger_exit then ob:on_trigger_exit(oa, c) end end
      else
        if oa.on_collision_exit then oa:on_collision_exit(ob, c) end
        if ob.on_collision_exit then ob:on_collision_exit(oa, c) end
      end
    end,
    function(fa, fb, c) --presolve
      local oa, ob = self:get_object_by_id(fa:getUserData()), self:get_object_by_id(fb:getUserData())
      if oa and ob then
        --pass
      end
    end
  )
  return self
end


-- Enables physical collision between objects of two tags
-- on_collision_enter and on_collision_exit callbacks will be called when objects of these two tags physically collide
-- By default, every object physically collides with every other object
-- group:set_as_physics_world(192, 0, 0, {'player', 'enemy', 'projectile', 'ghost', 'solid'})
-- group:enable_collision_between('player', 'enemy')
function Group:enable_collision_between(tag1, tag2)
  table.delete(self.collision_tags[tag1].masks, self.collision_tags[tag2].category)
end


-- Disables physical collision between objects of two tags
-- on_collision_enter and on_collision_exit callbacks will NOT be called when objects of these two tags pass through each other
-- group:set_as_physics_world(192, 0, 0, {'player', 'enemy', 'projectile', 'ghost', 'solid'})
-- group:disable_collision_between('ghost', 'solid')
-- group:disable_collision_between('player', 'projectile')
function Group:disable_collision_between(tag1, tag2)
  table.insert(self.collision_tags[tag1].masks, self.collision_tags[tag2].category)
end


-- Enables trigger collision between objects of two tags
-- When objects have physical collision disabled between one another, you might still want to have the engine generate enter and exit events when they start/stop overlapping
-- This is the function that makes that happen
-- group:set_as_physics_world(192, 0, 0, {'player', 'enemy', 'projectile', 'ghost', 'solid'})
-- group:disable_collision_between('ghost', 'solid')
-- group:enable_trigger_between('ghost', 'solid') -> now when a ghost passes through a solid, on_trigger_enter and on_trigger_exit will be called
function Group:enable_trigger_between(tag1, tag2)
  table.insert(self.trigger_tags[tag1].triggers, self.trigger_tags[tag2].category)
end


-- Disables trigger collision between objects of two tags
-- This will only work if enable_trigger_between has been called for a pair of tags
-- In general you shouldn't use this, as trigger collisions are disabled by default for all objects
function Group:disable_trigger_between(tag1, tag2)
  table.delete(self.trigger_tags[tag1].triggers, self.trigger_tags[tag2].category)
end


-- Returns a table of all physics objects that collide with the segment passed in
-- This requires that the group is set as a physics world first and only works on objects initialized as physics objects (see gameobject file)
-- This function returns a table of hits, each hit is of the following format: {
--   x = hit's x position, y = hit's y position,
--   nx = hit's x normal, ny = hit's y normal,
--   fraction = a number from 0 to 1 representing the fraction of the segment where the hit happened,
--   other = the object hit by the segment
-- }
-- So if the following call group:raycast(100, 100, 800 800) hits 3 objects, it will return something like this: {
--   [1] = {x = ..., y = ..., nx = ..., ny = ..., fraction = ..., other = the 1st object hit},
--   [2] = {x = ..., y = ..., nx = ..., ny = ..., fraction = ..., other = the 2nd object hit},
--   [3] = {x = ..., y = ..., nx = ..., ny = ..., fraction = ..., other = the 3rd object hit},
-- }
-- Where ... just stands for some number.
function Group:raycast(x1, y1, x2, y2)
  if not self.world then return end
  
  Profiler:start("physics_raycast")
  self.raycast_hitlist = {}
  self.world:rayCast(x1, y1, x2, y2, function(fixture, x, y, nx, ny, fraction)
    local hit = {}
    hit.fixture = fixture
    hit.x, hit.y = x, y
    hit.nx, hit.ny = nx, ny
    hit.fraction = fraction
    table.insert(self.raycast_hitlist, hit)
    return 1
  end)

  local hits = {}
  for _, hit in ipairs(self.raycast_hitlist) do
    local obj = self:get_object_by_id(hit.fixture:getUserData())
    hit.fixture = nil
    hit.other = obj
    table.insert(hits, hit)
  end
  Profiler:finish("physics_raycast")

  return hits
end
