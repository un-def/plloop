plloop — Python-like Lua Object-Oriented Programming system
===========================================================

`plloop` module provides a naive Lua OOP implementation that mimics Python OOP system. It implements automatic bound methods (forget about colon syntactic sugar), `__init__` method for new instance initializing, all metatable 'magic' (event) metamethods (e.g. `__tostring`, `__len`, `__call`, `__add`), multilevel (but not multiple) inheritance, and more.



### How to use it

```lua
#!/usr/bin/lua

local plloop = require('plloop')


local CurrySum = plloop.class('CurrySum', {

    -- def __init__(self, ...)
    __init__ = function(self, initial_value)
        self.value = self._convert_to_number(initial_value)
    end,

    -- def __str__(self)
    __tostring = function(self)
        return ('<%s obj: %s>'):format(self.__class__.__name__, self.value)
    end,

    -- def __call__(self, ...)
    __call = function(self, plus_value)
        self.value = self.value + self._convert_to_number(plus_value)
        return self
    end,

    -- def __add__(self, other)
    __add = function(self, other)
        return self.value + self._convert_to_number(other)
    end,

    get_value = function(self)
        return self.value
    end,

    set_value = function(self, value)
        self.value = self._convert_to_number(value)
    end,

    -- helper method
    _convert_to_number = function(self, raw)
        if type(raw) == 'table' and raw.__class__ == self.__class__ then
            raw = raw.value
        end
        return tonumber(raw) or 0
    end

})


print(CurrySum)    -- <CurrySum>

local sum1 = CurrySum(7)
print(sum1)    -- <CurrySum obj: 7>

sum1(3)('1')(nil)(10)
print(sum1)    -- <CurrySum obj: 21> (7+3+1+0+10)

local sum2 = CurrySum(23)
print(sum2)    -- <CurrySum obj: 23>

print(sum1 + sum2)    -- 44 (21+23)
print(sum1 + 5)    --- 26 (21+5)
print(sum2 + nil)    --- 23 (23+0)

local sum3 = CurrySum(sum2)
print(sum3)    -- <MyClass obj: 23>

sum3.set_value('43')
print(sum3.get_value())    -- 43
print(CurrySum.get_value(sum3))    -- 43
local bound_method = sum3.get_value
print(bound_method())    -- 43

print(sum1.__id__, sum2.__id__, sum3.__id__)    -- 0x928bb0    0x929e20    0x92a260
print(sum1.__class__, sum1.__class__.__name__)    --- <CurrySum>    CurrySum


local subclass_attrs = {

    -- overloaded method
    __tostring = function(self)
        return ('[%s obj: %s]'):format(self.__class__.__name__, self.value)
    end,

    -- additional method
    get_double_value = function(self)
        return self.value * 2
    end

}

-- Lua 5.3
local SubCurrySum = plloop.class('SubCurrySum', subclass_attrs) << CurrySum

-- all supported Lua versions
local SubCurrySum = plloop.class('SubCurrySum', subclass_attrs, CurrySum)


print(SubCurrySum)    -- <SubCurrySum>

local subsum = SubCurrySum(9)
print(subsum)    -- [SubCurrySum obj: 9]

print(subsum.get_value())    -- 9

subsum(8)({})(true)(12)('15')
print(subsum.get_value())    -- 44 (9+8+0+0+12+15)

print(subsum.get_double_value())    -- 88


print(plloop.is_object(subsum))    -- true
print(plloop.instance_of(subsum, SubCurrySum))    -- true
print(plloop.instance_of(subsum, CurrySum))    -- true
print(plloop.instance_of(subsum, CurrySum, true))    -- false (third arg - direct_only)
print(plloop.is_class(SubCurrySum))    -- true
print(plloop.subclass_of(SubCurrySum, CurrySum))    -- true
```


# How to test it

```$ ./run_tests.sh```

This script tests `plloop` with Lua 5.1, 5.2, and 5.3 (you need [luaunit](https://github.com/bluebird75/luaunit) module somewhere in `package.path`).



# Where is the documentation?

There is no documentation at the moment. Read `plloop.lua` and `plloop_tests.lua`.
