if type(jit) == 'table' and jit.status() then
	return require 'ffi'
else
	return false
end