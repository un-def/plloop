local VERSION = '0.0.1'

local metamethods = {
   '__add', '__sub', '__mul', '__div', '__mod', '__pow', '__unm', '__idiv',
   '__band', '__bor', '__bxor', '__bnot', '__shl', '__shr',
   '__concat', '__len', '__eq', '__lt', '__le',
   -- '__index', '__nexindex', '__tostring', '__call', '__metatable'
}

local function get_table_id(tbl)
   return tostring(tbl):sub(8)
end

local function get_method(cls, method_name)
   local method = rawget(cls, method_name)
   if type(method) == 'function' then return method end
end

-- temp workaround; we need __classid__ or something
local function is_class(obj, cls)
   if rawget(obj, '__class__') then
      return true
   else
      return false
   end
end

local function create_class(cls_name, attrs)

   local Class = {}
   local ClassMeta = {}

   Class.__name__ = cls_name
   Class.__class__ = Class
   Class.__classid__ = get_table_id(Class)
   Class.__meta__ = ClassMeta

   for key, value in pairs(attrs) do
      Class[key] = value
   end

   for _, metamethod in ipairs(metamethods) do
      ClassMeta[metamethod] = function(self, ...)
         if is_class(self, Class) then return end
         return Class[metamethod](self, ...)
      end
   end

   ClassMeta.__call = function(self, ...)
      -- class call (constructor + __init__)
      if is_class(self, Class) then
         local instance = {}
         instance.__id__ = get_table_id(instance)
         setmetatable(instance, ClassMeta)
         local init_method = get_method(Class, '__init__')
         if init_method then init_method(instance, ...) end
         return instance
      -- instance call (__call)
      else
         local call_method = get_method(Class, '__call')
         if call_method then return call_method(self, ...) end
      end
   end

   ClassMeta.__tostring = function(self)
      if is_class(self, Class) then
         return ('<%s>'):format(Class.__name__)
      else
         local tostring_method = get_method(Class, '__tostring')
         if tostring_method then
            return tostring_method(self)
         else
            return ('<%s instance: %s>'):format(Class.__name__, self.__id__)
         end
      end
   end

   ClassMeta.__index = function(self, key)
      if is_class(self, Class) then return end
      -- try to get class attribute
      local value = rawget(Class, key)
      -- bound method implementation
      if type(value) == 'function' then
         return function(...)
            return value(self, ...)
         end
      end
      -- __getattr__ implementation
      if value == nil then
         local index_method = get_method(Class, '__index')
         if index_method then return index_method(self, key) end
      end
      -- class attribute implementation (or nil)
      return value
   end

   ClassMeta.__newindex = function(self, key, value)
      if is_class(self, Class) then
         rawset(Class, key, value)
         return
      end
      -- __setattr__ implementation (like __getattr__, not __getattribute__)
      local newindex_method = get_method(Class, '__newindex')
      if newindex_method then
         newindex_method(self, key, value)
      else
         rawset(self, key, value)
      end
   end

   setmetatable(Class, ClassMeta)
   return Class

end


return {
   create_class = create_class,
   VERSION = VERSION,
}
