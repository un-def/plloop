local VERSION = '0.0.1'

local metamethods = {
   '__add', '__sub', '__mul', '__div', '__mod', '__pow', '__unm', '__idiv',
   '__band', '__bor', '__bxor', '__bnot', '__shl', '__shr',
   '__concat', '__len', '__lt', '__le',
   -- '__eq', '__index', '__nexindex', '__tostring', '__call', '__metatable'
}

local function bool(value)
   return not not value
end

local function get_table_id(tbl)
   return tostring(tbl):sub(8)
end

local function get_method(cls, method_name)
   local method = rawget(cls, method_name)
   if type(method) == 'function' then return method end
end

local function is_class(obj, cls)
   -- is_class(obj) - checks whether lua obj is a class (any)
   -- is_class(obj, cls) - checks whether lua obj is a 'cls' class
   if type(obj) ~= 'table' then return false end
   if not rawget(obj, '__class__') then
      return false
   elseif cls == nil then
      return true
   else
      return (obj.__classid__ == cls.__classid__)
   end
end

local function is_object(obj)
   -- checks whether lua obj is an object (class instance)
   if type(obj) ~= 'table' then return false end
   return bool(rawget(obj, '__id__'))
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
         if is_class(self) then return end
         return Class[metamethod](self, ...)
      end
   end

   ClassMeta.__call = function(self, ...)
      -- class call (constructor + __init__)
      if is_class(self) then
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
      if is_class(self) then
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

   ClassMeta.__eq = function(self, other)
      if is_class(self) then
         return is_class(self, other)
      else
         local eq_method = get_method(Class, '__eq')
         if eq_method then
            return eq_method(self, other)
         else
            if not is_object(other) then
               return false
            else
               return (self.__id__ == other.__id__)
            end
         end
      end
   end

   ClassMeta.__index = function(self, key)
      if is_class(self) then return end
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
      -- ignore class-only attribute
      if key == '__classid__' then return end
      -- class attribute implementation (or nil)
      return value
   end

   ClassMeta.__newindex = function(self, key, value)
      if is_class(self) then
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
   is_class = is_class,
   is_object = is_object,
   VERSION = VERSION,
}
