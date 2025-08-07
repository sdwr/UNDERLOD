-- File: achievements/AchievementsPanel.lua
-- A self-contained UI panel for displaying achievements, driven by the existing achievement data files.

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
    self.grid_y_offset = -10 -- Move grid down by 30 (was -40)
    
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
        section_header = {0.4, 0.4, 0.5, 0.9},
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
    self.achievement_info_text = nil

    -- Section headers
    self.section_headers = {
        [ACH_CATEGORY_PROGRESSION] = Text({{text = '[fg]Progression', font = pixul_font, alignment = 'center'}}, global_text_tags),
        [ACH_CATEGORY_COMBAT] = Text({{text = '[fg]Combat', font = pixul_font, alignment = 'center'}}, global_text_tags),
        [ACH_CATEGORY_ITEM] = Text({{text = '[fg]Items', font = pixul_font, alignment = 'center'}}, global_text_tags),
    }

    self:populate_slots()
end

function AchievementsPanel:populate_slots()
    -- Group achievements by category
    local achievements_by_category = {
        [ACH_CATEGORY_PROGRESSION] = {},
        [ACH_CATEGORY_COMBAT] = {},
        [ACH_CATEGORY_ITEM] = {},
    }
    
    -- Sort achievements into categories
    for i, id in ipairs(ACHIEVEMENTS_INDEX) do
        local data = ACHIEVEMENTS_TABLE[id]
        if not data then
            print("Warning: No data found for achievement ID: " .. id)
        else
            local category = data.category or ACH_CATEGORY_COMBAT -- Default to combat if no category
            table.insert(achievements_by_category[category], {id = id, data = data, original_index = i})
        end
    end
    
    -- Create slots organized by category with proper spacing
    local slot_index = 1
    local current_row = 0
    
    for category_index, category in ipairs({ACH_CATEGORY_PROGRESSION, ACH_CATEGORY_COMBAT, ACH_CATEGORY_ITEM}) do
        local achievements = achievements_by_category[category]
        
        -- Add achievements for this category
        for i, achievement in ipairs(achievements) do
            local col = (slot_index - 1) % self.columns
            local row = math.floor((slot_index - 1) / self.columns)
            
            local slot_x = self.x - self.grid_w / 2 + col * (self.slot_size + self.slot_padding) + self.slot_size / 2
            local slot_y = self.y - self.grid_h / 2 + row * (self.slot_size + self.slot_padding) + self.slot_size / 2 + self.grid_y_offset
            
            local slot = {
                id = achievement.id,
                data = achievement.data,
                category = category,
                x = slot_x, y = slot_y,
                w = self.slot_size, h = self.slot_size,
                is_hovered = false,
                row = row,
                is_first_in_section = i == 1,
                section_row = current_row,
            }
            -- Construct the icon path from the icon name
            slot.icon_image = love.graphics.newImage('assets/images/amplify.png')
            table.insert(self.slots, slot)
            
            slot_index = slot_index + 1
        end
        
        -- Calculate how many rows this section took
        local section_rows = math.ceil(#achievements / self.columns)
        current_row = current_row + section_rows
        
        -- Add spacing between sections (extra row)
        if category_index < 3 and #achievements > 0 then
            current_row = current_row + 1
            slot_index = current_row * self.columns + 1
        end
    end
end

function AchievementsPanel:update(dt)
    if not self.visible then return end

    self.title_text:update(dt)
    if self.reset_button then
        self.reset_button.text:update(dt)
    end
    
    -- Update section headers
    for _, header in pairs(self.section_headers) do
        header:update(dt)
    end
    
    local mx, my = camera:get_mouse_position()
    
    -- Check reset button hover
    if self.reset_button then
        self.reset_button.is_hovered = is_point_in_rectangle(mx, my, 
            self.reset_button.x - self.reset_button.w/2, 
            self.reset_button.y - self.reset_button.h/2, 
            self.reset_button.w, self.reset_button.h)
        
        -- Handle reset button click using standard input system
        if self.reset_button.is_hovered and input.m1.pressed then
            Reset_All_Achievements()
            Reset_User_Stats()
            return
        end
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
        
        -- Create InfoText with achievement data
        local text_lines = {
            {text = '[fg]' .. title, font = pixul_font, alignment = 'center'},
            {text = '', font = pixul_font, alignment = 'center'}, -- Empty line for spacing
            {text = desc, font = pixul_font, alignment = 'center'},
            {text = '', font = pixul_font, alignment = 'center'}, -- Empty line for spacing
            {text = unlocks, font = pixul_font, alignment = 'center'}
        }
        
        if not self.achievement_info_text then
            self.achievement_info_text = InfoText{group = main.current.ui, force_update = false}
        end
        self.achievement_info_text:activate(text_lines, nil, nil, nil, nil, 16, 4, nil, 2)
        local pos = Get_UI_Popup_Position()
        self.achievement_info_text.x = pos.x
        self.achievement_info_text.y = pos.y
        
    elseif not self.hovered_slot and self.selected_achievement then
        self.selected_achievement = nil
        if self.achievement_info_text then
            self.achievement_info_text:deactivate()
            self.achievement_info_text.dead = true
            self.achievement_info_text = nil
        end
    end
end

function AchievementsPanel:draw()
    if not self.visible then return end

    -- Draw main panel background
    local bg_color = bg[-2]
    love.graphics.setColor(bg_color.r, bg_color.g, bg_color.b, bg_color.a)
    love.graphics.rectangle('fill', self.x - self.w/2, self.y - self.h/2, self.w, self.h, 10)

    -- Draw reset button
    if self.reset_button then
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
    end

    self.title_text:draw(self.x, self.y - self.h/2 + 20)

    -- Draw section headers
    local section_headers_drawn = {}
    
    for _, slot in ipairs(self.slots) do
        -- Draw section header if this is the first slot in its section
        if slot.is_first_in_section and not section_headers_drawn[slot.category] then
            local header_y = self.y - self.grid_h / 2 + (slot.section_row * (self.slot_size + self.slot_padding)) + self.grid_y_offset - 15
            self.section_headers[slot.category]:draw(self.x, header_y)
            section_headers_drawn[slot.category] = true
        end
    end

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

    -- Achievement text is now handled by InfoText in the update function
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function AchievementsPanel:show()
    self.visible = true
end

function AchievementsPanel:hide()
    self.visible = false
end
