Helper.DamageNumbers = {}

Helper.DamageNumbers.LIMIT = 30
Helper.DamageNumbers.Queue = {}       -- The list of active damage number objects, sorted by damage amount.
Helper.DamageNumbers.TotalDamage = 0  -- A running total of all damage in the queue.
Helper.DamageNumbers.Average = 0      -- The cached average, updated on add/remove.
Helper.DamageNumbers.base_scale = 0.5

--- Initializes or resets the helper.
function Helper.DamageNumbers.Init()
    Helper.DamageNumbers.Queue = {}
    Helper.DamageNumbers.TotalDamage = 0
    Helper.DamageNumbers.Average = 0
end

--- Adds a new damage number object to the queue, keeping it sorted.
-- @param ft The damage number object. It must have a `.damage` property.
function Helper.DamageNumbers.Add(data)
  if not data or not data.damage or data.damage == 0 then return end

  -- First, do a periodic cleanup of any numbers that have faded out.
  Helper.DamageNumbers.CleanupDeadNumbers()

  --create a new floating text object scaled based on the damage
  local scale = Helper.DamageNumbers.GetRelativeScale(data.damage)
  data.scale = scale
  local ft = FloatingText(data)

  -- Find the correct position to insert the new number to keep the queue sorted.
  local insert_pos = #Helper.DamageNumbers.Queue + 1
  for i = 1, #Helper.DamageNumbers.Queue do
      if ft.damage < Helper.DamageNumbers.Queue[i].damage then
          insert_pos = i
          break
      end
  end
  table.insert(Helper.DamageNumbers.Queue, insert_pos, ft)
  Helper.DamageNumbers.TotalDamage = Helper.DamageNumbers.TotalDamage + ft.damage

  -- If the queue is now over the limit, remove the SMALLEST number.
  if #Helper.DamageNumbers.Queue > Helper.DamageNumbers.LIMIT then
      -- Because the queue is sorted, the smallest is always at index 1.
      local smallest = table.remove(Helper.DamageNumbers.Queue, 1)
      if smallest then
          Helper.DamageNumbers.TotalDamage = Helper.DamageNumbers.TotalDamage - smallest.damage
          if not smallest.dead and smallest.destroy then
              smallest:destroy() -- Instantly kill the smallest number
          end
      end
  end
  
  -- Recalculate and cache the new average.
  Helper.DamageNumbers.UpdateAverage()
end

--- Recalculates the average damage. Called internally.
function Helper.DamageNumbers.UpdateAverage()
    if #Helper.DamageNumbers.Queue > 0 then
        Helper.DamageNumbers.Average = Helper.DamageNumbers.TotalDamage / #Helper.DamageNumbers.Queue
    else
        Helper.DamageNumbers.Average = 0
    end
end

--- Removes any "dead" damage numbers from the queue.
function Helper.DamageNumbers.CleanupDeadNumbers()
    -- Iterate backwards to safely remove items from the table.
    for i = #Helper.DamageNumbers.Queue, 1, -1 do
        local v = Helper.DamageNumbers.Queue[i]
        if v.dead then
            Helper.DamageNumbers.TotalDamage = Helper.DamageNumbers.TotalDamage - v.damage
            table.remove(Helper.DamageNumbers.Queue, i)
        end
    end
end

--- Returns a scale multiplier based on how the damage compares to the average.
-- @param damage The damage amount of the new number.
function Helper.DamageNumbers.GetRelativeScale(damage)
    if Helper.DamageNumbers.Average == 0 then return Helper.DamageNumbers.base_scale end

    -- Use the square root of the ratio to create a dampened, non-linear curve.
    -- This prevents normal hits from scaling up too quickly due to a low average.
    local ratio = damage / Helper.DamageNumbers.Average
    local scale_bonus = (math.sqrt(ratio) - 1)
    
    -- Clamp the result to prevent extremely tiny or huge numbers.
    return math.clamp(Helper.DamageNumbers.base_scale * (1 + scale_bonus), 0.7, 2)
end


return Helper.DamageNumbers