local utils = {}

local function _explicit_struct_uniforms_usage(s)
	local struct_list = {}
	for struct_name, members in s:gmatch('struct ([%w_]*)%s*{(.*)};') do
		struct_list[struct_name] = members
	end
	local explicit_usage = ''
	for k, v in pairs(struct_list) do
		local t = {}
		for name in s:gmatch('uniform%s+' .. k .. '%s+([%w_]+)%s-%[.+%];') do
			table.insert(t, name .. '[0]')
		end
		for name in s:gmatch('uniform%s+' .. k .. '%s+([%w_]+)%s-;') do
			table.insert(t, name)
		end
		for name in v:gmatch('[%w_]+%s+([%w_]+)[%[%w_%]]-;') do
			for _, objname in ipairs(t) do
				explicit_usage = explicit_usage .. objname .. '.' .. name .. ';\n'
			end
		end
	end
	if #explicit_usage > 0 then
		local a, b = s:match('(.*vec4 effect.-{)(.*)')
		if not a or not b then
			a, b = s:match('(.*vec4 position.-{)(.*)')
		end
		return a .. explicit_usage .. b
	else
		return s
	end
end

function utils.shader_preprocess(code)
	return _explicit_struct_uniforms_usage(code)
end

function utils.noexcept_send_uniform(shader, name, value, ...)
	if value ~= nil and shader:hasUniform(name) then
      	shader:send(name, value, ...)
	end
end

function utils.copy(value)
      if type(value) ~= 'table' then return value end
      local t = setmetatable({}, getmetatable(value))
      for k, v in pairs(value) do
		t[utils.copy(k)] = utils.copy(v)
	end
      return t
end

function utils.binsearch(array, value)
	local l = 1
	local r = #array

	while r >= l do
		local m = math.floor((l + r) / 2)

		if array[m] < value then
			l = m + 1
		elseif array[m] > value then
			r = m - 1
		else
			return m
		end
	end

	return array[l] == value and l or l-1
end

return utils