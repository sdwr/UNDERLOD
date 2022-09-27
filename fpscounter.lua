FPSCounter = Object:extend()
function FPSCounter:init()
    self.show = false
    self.stack = Stack(120)
    self.fps = 0

    self.text = Text({{text = '[yellow]' .. tostring(self.fps), font = pixul_font, alignment = 'left'}}, global_text_tags)
end

function FPSCounter:update(dt)
    self.stack:push(dt or 0.01)
    self.fps = math.round(1 / self.stack.avg, 0)
    self.text:set_text({{text = '[yellow]' .. tostring(self.fps), font = pixul_font, alignment = 'left'}}, global_text_tags)
    self.text:update(dt)

    if input['lctrl'].down or input['rctrl'].down then
        if input['a'].pressed then
            self:toggleShow()
        end
    end
end

function FPSCounter:draw()
    if self.show then
        self.text:draw(10, 10)
    end
end

function FPSCounter:toggleShow()
    self.show = not self.show
end