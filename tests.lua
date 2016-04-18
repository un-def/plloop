#!/usr/bin/lua

luaunit = require('luaunit')
plloop = require('plloop')


TestClassCreation = {

   setUp = function(self)
      self.class = plloop.create_class('MyClass', {})
   end
   ,
   testClassIsTable = function(self)
      luaunit.assertIsTable(self.class)
   end
   ,
   testTostring = function(self)
      luaunit.assertEquals(tostring(self.class), '<MyClass>')
   end
   ,
   testSpecialAttrClassRefersToClass = function(self)
      luaunit.assertIs(self.class.__class__, self.class)
   end
   ,
   testSpecialAttrNameTostring = function(self)
      luaunit.assertEquals(
         tostring(self.class), ('<%s>'):format(self.class.__name__))
   end
   ,
   testSpecialAttrMetaRefersToClassMetatable = function(self)
      luaunit.assertIs(self.class.__meta__, getmetatable(self.class))
   end
   ,
   testSpecialAttrClassidPattern = function(self)
      luaunit.assertStrMatches(self.class.__classid__, '0x%w+')
   end

}


TestClassMeta = {

   setUp = function(self)
      self.class = plloop.create_class('MyClass', {})
   end
   ,
   testMetaCallIsFunction = function(self)
      luaunit.assertIsFunction(self.class.__meta__.__call)
   end
   ,
   testMetaTostringIsFunction = function(self)
      luaunit.assertIsFunction(self.class.__meta__.__tostring)
   end
   ,
   testMetaIndexIsFunction = function(self)
      luaunit.assertIsFunction(self.class.__meta__.__index)
   end
   ,
   testMetaNewindexIsFunction = function(self)
      luaunit.assertIsFunction(self.class.__meta__.__newindex)
   end

}


TestMethods = {

   setUp = function(self)
      self.class = plloop.create_class('MyClass', {
         __init__ = function(self, initial)
            self.value = initial
         end
         ,
         get_value = function(self)
            return self.value
         end
         ,
         set_value = function(self, value)
            self.value = value
         end
      })
   end
   ,
   testInitMethod = function(self)
      local obj = self.class(10)
      luaunit.assertEquals(obj.value, 10)
   end
   ,
   testRegularMethodSetter = function(self)
      local obj = self.class()
      obj.set_value(20)
      luaunit.assertEquals(obj.value, 20)
   end
   ,
   testRegularMethodGetter = function(self)
      local obj = self.class(30)
      luaunit.assertEquals(obj.get_value(), 30)
   end
   ,
   testDynamicallyAddedRegularMethod = function(self)
      local obj = self.class(40)
      self.class.get_double_value = function(self)
         return self.value * 2
      end
      luaunit.assertEquals(obj.get_double_value(), 80)
   end
   ,
   testOverloadedRegularMethod = function(self)
      local obj = self.class(50)
      self.class.get_value = function(self)
         return self.value + 1
      end
      luaunit.assertEquals(obj.get_value(), 51)
   end

}


TestMetamethods = {

   setUp = function(self)
      self.class_tostring_default = plloop.create_class(
         'TostringDefaultClass', {})
      self.class_tostring_custom = plloop.create_class(
         'TostringCustomClass',
         {
            __tostring = function(self)
               return ('[%s:%s]'):format(self.__class__.__name__, self.__id__)
            end
         }
      )
      self.class_add_custom = plloop.create_class('AddCustomClass', {
         __init__ = function(self, value)
            self.value = value
         end,
         __add = function(self, other)
            return self.value + other.value
         end
      })
   end
   ,
   testDefaultTostringMetamethod = function(self)
      local obj = self.class_tostring_default()
      luaunit.assertStrMatches(
         tostring(obj), '<TostringDefaultClass instance: 0x%w+>')
   end
   ,
   testCustomTostringMetamethod = function(self)
      local obj = self.class_tostring_custom()
      luaunit.assertStrMatches(tostring(obj), '%[TostringCustomClass:0x%w+%]')
   end
   ,
   testOverloadedTostringMetamethod = function(self)
      self.class_tostring_custom.__tostring = function(self)
         return ('<Overloaded:%s>'):format(self.__id__)
      end
      local obj = self.class_tostring_custom()
      luaunit.assertStrMatches(tostring(obj), '<Overloaded:0x%w+%>')
   end
   ,
   testCustomAddMetamethod = function(self)
      local obj1 = self.class_add_custom(5)
      local obj2 = self.class_add_custom(7)
      luaunit.assertEquals(obj1 + obj2, 12)
   end
   ,
   testOverloadedAddMetamethod = function(self)
      local obj1 = self.class_add_custom(5)
      local obj2 = self.class_add_custom(7)
      local new_add = function(self, other)
         return self.value + other.value + 5
      end
      self.class_add_custom.__add = new_add
      luaunit.assertEquals(obj1 + obj2, 17)
   end
   ,
   testDynamicallyAddedLenMetamethod = function(self)
      local obj = self.class_add_custom(333)
      local len = function(self)
         return 50
      end
      self.class_add_custom.__len = len
      luaunit.assertEquals(#obj, 50)
   end
}


os.exit(luaunit.LuaUnit.run())
