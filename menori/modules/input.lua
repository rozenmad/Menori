--[[
-------------------------------------------------------------------------------
      Menori
      @author rozenmad
      2021
-------------------------------------------------------------------------------
]]

local button_list = {}

local input = {}

local function _create_keycheck(fn)
      return function(button, press_repeat)
            if press_repeat == nil then press_repeat = true end

            local state = fn(button)
            if press_repeat then return state end

            if state and button_list[button] then return false end
            button_list[button] = state
            return state
      end
end

input.keyboard_is_down = _create_keycheck(love.keyboard.isDown)
input.mouse_is_down    = _create_keycheck(love.mouse.isDown)

return input