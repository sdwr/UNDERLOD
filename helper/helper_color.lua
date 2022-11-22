Helper.Color = {}

Helper.Color.blue = {r = 51 / 255, g = 153 / 255, b = 255 / 255, a = 1}
Helper.Color.green = {r = 36 / 255, g = 242 / 255, b = 67 / 255, a = 1}
Helper.Color.orange = {r = 255 / 255, g = 153 / 255, b = 51 / 255, a = 1}
Helper.Color.red = {r = 255 / 255, g = 51 / 255, b = 51 / 255, a = 1}
Helper.Color.white = {r = 1, g = 1, b = 1, a = 1}

function Helper.Color:set_transparency(color, a)
    local transparent_color = {
        r = color.r,
        g = color.g,
        b = color.b,
        a = a
    }
    return transparent_color
end

function Helper.Color:set_color(color)
    love.graphics.setColor(color.r, color.g, color.b, color.a)
end