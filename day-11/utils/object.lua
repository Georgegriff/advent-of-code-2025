---@class Object
---@field new fun(self: Object, ...): Object
---@field extend fun(self: Object): any
---@field is fun(self: Object, class: any): boolean
---@field super Object
local Object = require 'utils.classic'

return Object
