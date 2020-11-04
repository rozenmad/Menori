--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

--- Input manager.
-- @module Input
local button_list = {}

local Input = {}

--- Button constants.
Input.button = {
	A = 'z', -- kp1
	B = 'x', -- kp2
	W_arrow = 'kp8', -- w
	A_arrow = 'kp4', -- a
	S_arrow = 'kp5', -- s
	D_arrow = 'kp6', -- d
	W_arrow_ex = 'up',
	A_arrow_ex = 'left',
	S_arrow_ex = 'down',
	D_arrow_ex = 'right',
}

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

Input.keyboard_is_down = _create_keycheck(love.keyboard.isDown)
Input.mouse_is_down = _create_keycheck(love.mouse.isDown)

--- Button A
Input.key_a = function(press_repeat)
	return Input.keyboard_is_down(Input.button.A, press_repeat)
end
--- Button B
Input.key_b = function(press_repeat)
	return Input.keyboard_is_down(Input.button.B, press_repeat)
end

--- Button Move W
Input.key_move_w = function(press_repeat)
	return Input.keyboard_is_down(Input.button.W_arrow, press_repeat) or Input.keyboard_is_down(Input.button.W_arrow_ex, press_repeat)
end
--- Button Move A
Input.key_move_a = function(press_repeat)
	return Input.keyboard_is_down(Input.button.A_arrow, press_repeat) or Input.keyboard_is_down(Input.button.A_arrow_ex, press_repeat)
end
--- Button Move S
Input.key_move_s = function(press_repeat)
	return Input.keyboard_is_down(Input.button.S_arrow, press_repeat) or Input.keyboard_is_down(Input.button.S_arrow_ex, press_repeat)
end
--- Button Move D
Input.key_move_d = function(press_repeat)
	return Input.keyboard_is_down(Input.button.D_arrow, press_repeat) or Input.keyboard_is_down(Input.button.D_arrow_ex, press_repeat)
end

--- Button Space
Input.key_space = function(press_repeat)
	return Input.keyboard_is_down('c', press_repeat)
end

return Input