local modules = (...):gsub('%.[^%.]+$', '') .. "."

local utils = {}

function utils.all(t)
    local b = true
    for i, v in ipairs(t) do
        if not v then b = false end
    end
    return b
end

function utils.round(v)
    return (v >= 0.0) and math.floor(v + 0.5) or math.ceil(v - 0.5)
end

return utils