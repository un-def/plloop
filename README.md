plloop — Python-like Lua Object-Oriented Programming system
===========================================================

`plloop` module provides a naive Lua OOP implementation, just like in Python, but ugly. And without inheritance (at all). And ugly. Made in one night. J4F.



### How to use it

```
local plloop = require('plloop')


local myclass = plloop.create_class('MyClass', {

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


print(myclass)   -- <MyClass>

local obj1 = myclass(7)
print(obj1)   -- <MyClass obj: 7>

obj1(3)('1')(nil)(10)
print(obj1)   -- <MyClass obj: 21> (7+3+1+0+10)

local obj2 = myclass(23)
print(obj2)   -- <MyClass obj: 23>

print(obj1 + obj2)   -- 44 (21+23)
print(obj1 + 5)   --- 26 (21+5)
print(obj2 + nil)   --- 23 (23+0)

local obj3 = myclass(obj2)
print(obj3)   -- <MyClass obj: 23>

obj3.set_value('43')
print(obj3.get_value())   -- 43
print(myclass.get_value(obj3))   -- 43
local bound_method = obj3.get_value
print(bound_method())   -- 43
print(type(bound_method()))   -- number

print(obj1.__id__, obj2.__id__, obj3.__id__)   -- 0x928bb0    0x929e20    0x92a260
print(obj1.__class__, obj1.__class__.__name__)   --- <MyClass>    MyClass
print(obj1.__meta__ == getmetatable(obj1))   -- true
```


# How to test it

```$ ./run_tests.sh```

This script tests `plloop` with Lua 5.1, 5.2, and 5.3.



# Where is the documentation?

There is no documentation at the moment. Read `plloop.lua`. Yep.
