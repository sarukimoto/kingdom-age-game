Timer = { --minute:second countdown timer
    spentTime = 0,
    updateTicks = 1,
    onUpdate = nil
}

function Timer:new(duration)
    local timer = {}
    timer.duration = math.min(duration / 1000)
    timer.minutes = math.min(timer.duration / 60)
    timer.seconds = timer.duration % 60
    return setmetatable(timer, { __index = Timer })
end

function Timer:getString()
    return string.format("%.2d:%.2d", self.minutes, self.seconds)
end

function Timer:getPercent()
    return 100 - 100 * self.spentTime / self.duration
end

function Timer:getRemainingTime()
    return self.duration - self.spentTime
end

function Timer:start()
    self.event = cycleEvent(function() self:update() end, self.updateTicks * 1000)
end

function Timer:stop()
    self.event:cancel()
end

function Timer:destroy()
    self:stop()
    self.onUpdate = nil
end

function Timer:update()
    self.spentTime = self.spentTime + self.updateTicks

--countdown
    if self.spentTime > self.duration then
        self.minutes = 0
        self.seconds = 0
        self:stop()
        return
    end

    if self.seconds < self.updateTicks then
        self.minutes = self.minutes - 1
        self.seconds = 60 + self.seconds - self.updateTicks
    else
        self.seconds = self.seconds - self.updateTicks
    end

    if self.onUpdate then
        self:onUpdate()
    end
end

