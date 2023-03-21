local modules = (...) and (...):gsub('%.init$', '') .. ".modules." or ""

local ml = {
}

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

for _, file in ipairs(files) do
      ml[file] = require(modules .. file)
end

return ml