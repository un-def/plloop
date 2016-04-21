local VERSION = '0.0.1'

local metamethods = {
    '__add', '__sub', '__mul', '__div', '__mod', '__pow', '__unm', '__idiv',
    '__band', '__bor', '__bxor', '__bnot', '__shl', '__shr',
    '__concat', '__len', '__lt', '__le',
    -- '__eq', '__index', '__nexindex', '__tostring', '__call', '__metatable'
}

local cls_attrs = {
    __name__ = true,
    __classid__ = true,
    __superclass__ = true,
}

local function bool(value)
    return not not value
end

local function get_table_id(tbl)
    return tostring(tbl):sub(8)
end

local function get_method(cls, method_name)
    local method = cls[method_name]
    if type(method) == 'function' then return method end
end

local function is_class(obj, cls)
    -- is_class(obj) - checks whether lua obj is a class (any)
    -- is_class(obj, cls) - checks whether lua obj is a 'cls' class
    if type(obj) ~= 'table' or not rawget(obj, '__classid__') then
        return false
    elseif cls == nil then
        return true
    else
        if not is_class(cls) then return false end
        return rawequal(obj, cls)
    end
end

local function is_object(obj)
    -- checks whether lua obj is an object (class instance)
    if type(obj) ~= 'table' then return false end
    return bool(rawget(obj, '__id__'))
end

local function instance_of(obj, cls)
    -- checks whether 'obj' is an instance of 'cls'
    if not is_object(obj) or not is_class(cls) then return false end
    return (obj.__class__ == cls)
end

local function set_superclass(cls, super_cls)
    if (not is_class(cls) or not is_class(super_cls) or
        is_class(cls, super_cls)) then return false end
    cls.__superclass__ = super_cls
    return true
end

local function create_class(name, attrs, super_cls)
    local cls = {}
    cls.__name__ = name
    cls.__classid__ = get_table_id(cls)
    set_superclass(cls, super_cls)
    for key, value in pairs(attrs) do
        cls[key] = value
    end
    setmetatable(cls, meta)
    return cls
end


meta = {}

for _, metamethod_name in ipairs(metamethods) do
    meta[metamethod_name] = function(self, ...)
        if is_class(self) then return end
        local metamethod = get_method(self.__class__, metamethod_name)
        if not metamethod then return end
        return metamethod(self, ...)
    end
end

meta.__call = function(self, ...)
    -- class call (constructor + __init__)
    if is_class(self) then
        local instance = {}
        instance.__id__ = get_table_id(instance)
        instance.__class__ = self
        setmetatable(instance, meta)
        local init_method = get_method(self, '__init__')
        if init_method then init_method(instance, ...) end
        return instance
    -- instance call (__call)
    else
        local call_method = get_method(self.__class__, '__call')
        if call_method then return call_method(self, ...) end
    end
end

meta.__tostring = function(self)
    if is_class(self) then
        return ('<%s>'):format(self.__name__)
    else
        local tostring_method = get_method(self.__class__, '__tostring')
        if tostring_method then
            return tostring_method(self)
        else
            return ('<%s instance: %s>'):format(
                self.__class__.__name__, self.__id__)
        end
    end
end

meta.__eq = function(self, other)
    if is_class(self) then
        return is_class(self, other)
    else
        local eq_method = get_method(self.__class__, '__eq')
        if eq_method then
            return eq_method(self, other)
        else
            return rawequal(self, other)
        end
    end
end

-- sugar: class << superclass - set superclass (works only with Lua 5.3+)
meta.__shl = function(self, value)
    if is_class(self) then
        set_superclass(self, value)
        return self
    else
        local shl_method = get_method(self.__class__, '__shl')
        if shl_method then return shl_method(self, value) end
    end
end

meta.__index = function(self, key)
    if is_class(self) then
        -- inheritance
        local super_cls = rawget(self, '__superclass__')
        if not is_class(super_cls) then return end
        return super_cls[key]
    end
    -- try to get class attribute
    local value = self.__class__[key]
    -- bound method implementation
    if type(value) == 'function' then
        return function(...)
            return value(self, ...)
        end
    end
    -- __getattr__ implementation
    if value == nil then
        local index_method = get_method(self.__class__, '__index')
        if index_method then return index_method(self, key) end
    end
    -- ignore class-only attribute
    if cls_attrs[key] then return end
    -- class attribute implementation (or nil)
    return value
end

meta.__newindex = function(self, key, value)
    if is_class(self) then
        rawset(self, key, value)
        return
    end
    -- __setattr__ implementation (like __getattr__, not __getattribute__)
    local newindex_method = get_method(self.__class__, '__newindex')
    if newindex_method then
        newindex_method(self, key, value)
    else
        rawset(self, key, value)
    end
end


return {
    create_class = create_class,
    is_class = is_class,
    is_object = is_object,
    instance_of = instance_of,
    VERSION = VERSION,
}
