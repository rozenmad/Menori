local modules = (...) and (...):gsub('%.init$', '') .. ".modules." or ""

local files = {
	"utils",
	"vec2",
	"vec3",
	"vec4",
	"mat4",
	"quat",
	"bound3",
	"bvh",
	"intersect"
}

local ml = {}
for _, file in ipairs(files) do
	ml[file] = require(modules .. file)
end

return ml