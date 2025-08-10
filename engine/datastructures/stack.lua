Stack = Object:extend()
Stack.__class_name = 'Stack'
function Stack:init(maxSize)
    self.out = {}
    self.maxSize = maxSize or 0
    self.avg = 0.0
end

function Stack:push(v)
    if self.maxSize > 0 and #self.out > self.maxSize then
        local removed = self:popFirst()
        if removed then
            self.avg = self.avg - ((removed*1.0)/self.maxSize)
        end
    end

    self.out[#self.out+1] = v
    self.avg = self.avg + ((v*1.0)/self.maxSize)
end

function Stack:pop()
    if #self.out>0 then
        local ret = table.remove(self.out, #self.out)
        self.avg = self.avg - ((ret*1.0)/self.maxSize)
    end
end

function Stack:popFirst()
    if #self.out>0 then
        local ret = table.remove(self.out, 1)
        self.avg = self.avg - ((ret*1.0)/self.maxSize)
    end
end