-- File: achievements/AchievementsPanel.lua
-- A self-contained UI panel for displaying achievements, driven by the existing achievement data files.

require 'achievements/achievement_unlocks' -- Use the existing achievement data file

AchievementsPanel = Object:extend()
AchievementsPanel:implement(GameObject)
function AchievementsPanel:init(args)
    self:init_game_object(args)
    self.x = args.x or gw - 100 -- Move to right side
    self.y = args.y or gh / 2 -- Move down a bit

    self.show_reset_button = true
    
    -- Grid layout properties to fit the 34 achievements in top 3/4 of screen
    self.columns = 6
    self.rows = 6
    self.slot_size = 20 -- Much smaller slots
    self.slot_padding = 2 -- Minimal padding
    self.grid_w = self.columns * (self.slot_size + self.slot_padding) - self.slot_padding
    self.grid_h = self.rows * (self.slot_size + self.slot_padding) - self.slot_padding
    self.grid_y_offset = -40 -- Offset for the grid
    
    -- Adjust panel size to match grid + space for text at bottom
    self.w = self.grid_w + 20 -- Add small margin
    self.h = self.grid_h + 140 -- Add margin for title and bottom text section
    self.visible = true
    self.slots = {}
    
    -- Colors for different states
    self.colors = {
        locked_bg = {0.1, 0.1, 0.1, 0.8},
        unlocked_bg = {0.2, 0.2, 0.25, 0.8},
        active_border = {1, 0.8, 0.2, 1},
        hover_bg = {0.3, 0.3, 0.35, 0.8},
        white_border = {1, 1, 1, 1},
        button_bg = {0.3, 0.1, 0.1, 0.8},
        button_hover = {0.4, 0.15, 0.15, 0.8},
    }

    self.title_text = Text({{text = 'Achievements', font = pixul_font, alignment = 'center'}}, global_text_tags)
    
    -- Reset All button
    if self.show_reset_button then
    self.reset_button = {
        x = self.x - self.w/2, -- Left of title
        y = self.y - self.h/2 + 20, -- Same y as title
        w = 50,
        h = 20,
          text = Text({{text = 'Reset All', font = pixul_font, alignment = 'center'}}, global_text_tags),
          is_hovered = false
        }
    end
    
    -- Text section for selected achievement
    self.selected_achievement = nil
    self.achievement_title_text = nil
    self.achievement_desc_text = nil
    self.achievement_unlocks_text = nil

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
            local slot_y = self.y - self.grid_h / 2 + row * (self.slot_size + self.slot_padding) + self.slot_size / 2 + self.grid_y_offset -- Move grid up 20 pixels
            
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
    self.reset_button.text:update(dt)
    
    local mx, my = camera:get_mouse_position()
    
    -- Check reset button hover
    self.reset_button.is_hovered = is_point_in_rectangle(mx, my, 
        self.reset_button.x - self.reset_button.w/2, 
        self.reset_button.y - self.reset_button.h/2, 
        self.reset_button.w, self.reset_button.h)
    
    -- Handle reset button click using standard input system
    if self.reset_button.is_hovered and input.m1.pressed then
        Reset_All_Achievements()
        return
    end
    
    self.hovered_slot = nil
    for _, slot in ipairs(self.slots) do
        if is_point_in_rectangle(mx, my, slot.x - slot.w/2, slot.y - slot.h/2, slot.w, slot.h) then
            slot.is_hovered = true
            self.hovered_slot = slot
        else
            slot.is_hovered = false
        end
    end
    
    -- Update achievement text if selection changed
    if self.hovered_slot and self.hovered_slot ~= self.selected_achievement then
        self.selected_achievement = self.hovered_slot
        local is_unlocked = ACHIEVEMENTS_UNLOCKED[self.selected_achievement.id]
        local title = self.selected_achievement.data.name
        local desc = self.selected_achievement.data.desc
        local unlocks = self.selected_achievement.data.unlocks or 'unlocks xxx'
        self.achievement_title_text = Text({{text = '[fg]' .. title, font = pixul_font, alignment = 'center'}}, global_text_tags)
        self.achievement_desc_text = Text({{text = desc, font = pixul_font, alignment = 'center'}}, global_text_tags)
        self.achievement_unlocks_text = Text({{text = unlocks, font = pixul_font, alignment = 'center'}}, global_text_tags)
    elseif not self.hovered_slot and self.selected_achievement then
        self.selected_achievement = nil
        self.achievement_title_text = nil
        self.achievement_desc_text = nil
        self.achievement_unlocks_text = nil
    end
    
    -- Update text objects
    if self.achievement_title_text then
        self.achievement_title_text:update(dt)
    end
    if self.achievement_desc_text then
        self.achievement_desc_text:update(dt)
    end
    if self.achievement_unlocks_text then
        self.achievement_unlocks_text:update(dt)
    end
end

function AchievementsPanel:draw()
    if not self.visible then return end

    -- Draw main panel background
    local bg_color = bg[-2]
    love.graphics.setColor(bg_color.r, bg_color.g, bg_color.b, bg_color.a)
    love.graphics.rectangle('fill', self.x - self.w/2, self.y - self.h/2, self.w, self.h, 10)

    -- Draw reset button
    if self.reset_button.is_hovered then
        love.graphics.setColor(self.colors.button_hover)
    else
        love.graphics.setColor(self.colors.button_bg)
    end
    love.graphics.rectangle('fill', 
        self.reset_button.x - self.reset_button.w/2, 
        self.reset_button.y - self.reset_button.h/2, 
        self.reset_button.w, self.reset_button.h, 5)
    
    -- Draw reset button border
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle('line', 
        self.reset_button.x - self.reset_button.w/2, 
        self.reset_button.y - self.reset_button.h/2, 
        self.reset_button.w, self.reset_button.h, 5)
    
    -- Draw reset button text
    self.reset_button.text:draw(self.reset_button.x, self.reset_button.y)

    self.title_text:draw(self.x, self.y - self.h/2 + 20)

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
        local border_color = self.colors.white_border
        if is_unlocked then
          border_color = {yellow[0].r, yellow[0].g, yellow[0].b, yellow[0].a} 
        end
        love.graphics.setColor(border_color)
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

    -- Draw achievement text section at bottom
    if self.achievement_title_text and self.achievement_desc_text then
        -- Draw title
        self.achievement_title_text:draw(self.x, self.y + self.grid_h/2 - 20)
        
        -- Draw description
        self.achievement_desc_text:draw(self.x, self.y + self.grid_h/2 + 5)

        -- Draw unlocks
        self.achievement_unlocks_text:draw(self.x, self.y + self.grid_h/2 + 35)
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function AchievementsPanel:reset_all_achievements()
    -- Reset all achievements to false
    for achievement_id, _ in pairs(ACHIEVEMENTS_UNLOCKED) do
        ACHIEVEMENTS_UNLOCKED[achievement_id] = false
    end
    
    -- Save the reset state
    if state then
        state.achievements_unlocked = ACHIEVEMENTS_UNLOCKED
        system.save_state()
    end
    
    print("All achievements have been reset!")
end

function AchievementsPanel:show()
    self.visible = true
end

function AchievementsPanel:hide()
    self.visible = false
end
