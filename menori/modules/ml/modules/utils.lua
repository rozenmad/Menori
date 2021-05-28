local utils = {}

function utils.all(t)
    local b = true
    for i, v in ipairs(t) do
        if not v then b = false end
    end
    return b
end

return utils