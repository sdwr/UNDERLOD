-- File: achievements/AchievementsPanel.lua
-- A self-contained UI panel for displaying achievements, driven by the existing achievement data files.

require 'achievements/achievement_unlocks' -- Use the existing achievement data file

AchievementsPanel = Object:extend()
AchievementsPanel:implement(GameObject)
function AchievementsPanel:init(args)
    self:init_game_object(args)
    self.x = args.x or gw - 100 -- Move to right side
    self.y = args.y or gh / 2
    
    -- Grid layout properties to fit the 34 achievements
    self.columns = 5
    self.rows = 7
    self.slot_size = 24 -- Even smaller slots
    self.slot_padding = 3 -- Minimal padding
    self.grid_w = self.columns * (self.slot_size + self.slot_padding) - self.slot_padding
    self.grid_h = self.rows * (self.slot_size + self.slot_padding) - self.slot_padding
    
    -- Adjust panel size to match grid
    self.w = self.grid_w + 20 -- Add small margin
    self.h = self.grid_h + 40 -- Add margin for title and bottom
    self.visible = true
    self.slots = {}
    
    -- Colors for different states
    self.colors = {
        locked_bg = {0.1, 0.1, 0.1, 0.8},
        unlocked_bg = {0.2, 0.2, 0.25, 0.8},
        active_border = {1, 0.8, 0.2, 1},
        hover_bg = {0.3, 0.3, 0.35, 0.8},
        white_border = {1, 1, 1, 1},
    }

    self.title_text = Text({{text = 'AAchievements', font = pixul_font, alignment = 'center'}}, global_text_tags)

    self:populate_slots()
end

function AchievementsPanel:populate_slots()
    -- Iterate through the ordered index of achievements from your file
    for i, id in ipairs(ACHIEVEMENTS_INDEX) do
        local data = ACHIEVEMENTS_TABLE[id]
        if not data then
            print("Warning: No data found for achievement ID: " .. id)
        else
            local col = (i - 1) % self.columns
            local row = math.floor((i - 1) / self.columns)
            
            local slot_x = self.x - self.grid_w / 2 + col * (self.slot_size + self.slot_padding) + self.slot_size / 2
            local slot_y = self.y - self.grid_h / 2 + row * (self.slot_size + self.slot_padding) + self.slot_size / 2 -- Removed offset for title
            
            local slot = {
                id = id,
                data = data,
                x = slot_x, y = slot_y,
                w = self.slot_size, h = self.slot_size,
                is_hovered = false,
            }
            -- Construct the icon path from the icon name
            slot.icon_image = love.graphics.newImage('assets/images/amplify.png')
            table.insert(self.slots, slot)
        end
    end
end

function AchievementsPanel:update(dt)
    if not self.visible then return end

    self.title_text:update(dt)
    local mx, my = camera:get_mouse_position()
    self.hovered_slot = nil
    for _, slot in ipairs(self.slots) do
        if is_point_in_rectangle(mx, my, slot.x - slot.w/2, slot.y - slot.h/2, slot.w, slot.h) then
            slot.is_hovered = true
            self.hovered_slot = slot -- Keep track of the hovered slot for the tooltip
            
            -- Show info text for hovered slot
            if not self.info_text then
                self.info_text = InfoText{group = main.current.ui}
            end
            
            local is_unlocked = ACHIEVEMENTS_UNLOCKED[slot.id]
            local title = slot.data.name
            local text = is_unlocked and slot.data.desc or "Locked"
            
            self.info_text:activate({
                {text = '[fg]' .. title, font = pixul_font, alignment = 'center'},
                {text = text, font = pixul_font, alignment = 'center'},
            }, nil, nil, nil, nil, 16, 4, nil, 2)
            self.info_text.x, self.info_text.y = gw/2, gh/2
        else
            slot.is_hovered = false
        end
    end
    
    -- Hide info text if no slot is hovered
    if not self.hovered_slot and self.info_text then
        self.info_text:deactivate()
        self.info_text.dead = true
        self.info_text = nil
    end
end

function AchievementsPanel:draw()
    if not self.visible then return end

    -- Draw main panel background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', self.x - self.w/2, self.y - self.h/2, self.w, self.h, 10)

    self.title_text:draw(self.x, self.y - self.h/2 + 10)

    -- Draw slots
    for _, slot in ipairs(self.slots) do
        local is_unlocked = ACHIEVEMENTS_UNLOCKED[slot.id]
        -- is_active_check doesn't exist in your new data, so we'll default to false.
        -- This could be added to ACHIEVEMENTS_TABLE later if needed.
        local is_active = false 
        
        -- Determine background color
        if slot.is_hovered and is_unlocked then
            love.graphics.setColor(self.colors.hover_bg)
        elseif is_unlocked then
            love.graphics.setColor(self.colors.unlocked_bg)
        else
            love.graphics.setColor(self.colors.locked_bg)
        end
        love.graphics.rectangle('fill', slot.x - slot.w/2, slot.y - slot.h/2, slot.w, slot.h)

        -- Draw white border
        love.graphics.setColor(self.colors.white_border)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle('line', slot.x - slot.w/2, slot.y - slot.h/2, slot.w, slot.h)

        -- Draw icon, desaturated if locked
        if is_unlocked then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
        end
        local icon_scale = (self.slot_size * 0.6) / slot.icon_image:getWidth()
        love.graphics.draw(slot.icon_image, slot.x, slot.y, 0, icon_scale, icon_scale, slot.icon_image:getWidth()/2, slot.icon_image:getHeight()/2)

        -- Draw active border if applicable
        if is_active then
            love.graphics.setColor(self.colors.active_border)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle('line', slot.x - slot.w/2, slot.y - slot.h/2, slot.w, slot.h)
            love.graphics.setLineWidth(1)
        end
    end

    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function AchievementsPanel:mousepressed(x, y, button)
    if not self.visible then return end
    if button == 1 then
        for _, slot in ipairs(self.slots) do
            if slot.is_hovered then
                print("Clicked on achievement: " .. slot.data.name)
            end
        end
    end
end

function AchievementsPanel:show()
    self.visible = true
end

function AchievementsPanel:hide()
    self.visible = false
end
