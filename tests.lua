#!/usr/bin/lua

luaunit = require('luaunit')
plloop = require('plloop')


_, _, LUA_VERSION_MAJOR, LUA_VERSION_MINOR = _VERSION:find('^Lua (%d)%.(%d)')
LUA_VERSION = tonumber(LUA_VERSION_MAJOR .. LUA_VERSION_MINOR)
LUA_VERSION_MAJOR = tonumber(LUA_VERSION_MAJOR)
LUA_VERSION_MINOR = tonumber(LUA_VERSION_MINOR)


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
   testSpecialAttrNameTostring = function(self)
      luaunit.assertEquals(
         tostring(self.class), ('<%s>'):format(self.class.__name__))
   end
   ,
   testSpecialAttrClassidPattern = function(self)
      luaunit.assertStrMatches(self.class.__classid__, '0x%w+')
   end

}


TestClassMeta = {

   setUp = function(self)
      self.class = plloop.create_class('MyClass', {})
      self.meta = getmetatable(self.class)
   end
   ,
   testMetaCallIsFunction = function(self)
      luaunit.assertIsFunction(self.meta.__call)
   end
   ,
   testMetaTostringIsFunction = function(self)
      luaunit.assertIsFunction(self.meta.__tostring)
   end
   ,
   testMetaEqIsFunction = function(self)
      luaunit.assertIsFunction(self.meta.__eq)
   end
   ,
   testMetaIndexIsFunction = function(self)
      luaunit.assertIsFunction(self.meta.__index)
   end
   ,
   testMetaNewindexIsFunction = function(self)
      luaunit.assertIsFunction(self.meta.__newindex)
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
      local expected
      -- Lua < 5.2 doesn't support __len metamethod
      if LUA_VERSION > 51 then
         expected = 50
      else
         expected = 0
      end
      luaunit.assertEquals(#obj, expected)
   end
   ,
   testClassEqMetamethodSameClassIsEqual = function(self)
      luaunit.assertTrue(
         self.class_tostring_default == self.class_tostring_default)
   end
   ,
   testClassEqMetamethodDifferentClassesAreNotEqual = function(self)
      luaunit.assertFalse(
      self.class_tostring_default == self.class_tostring_custom)
   end
   ,
   testClassEqMetamethodClassAndTableAreNotEqual = function(self)
      luaunit.assertFalse(self.class_tostring_default == {})
   end
   ,
   testClassEqMetamethodClassAndSameClassObjectAreNotEqual = function(self)
      local obj = self.class_tostring_default()
      luaunit.assertFalse(self.class_tostring_default == obj)
   end
   ,
   testClassEqMetamethodClassAndDifferentClassObjectAreNotEqual = function(
         self)
      local obj = self.class_tostring_custom()
      luaunit.assertFalse(self.class_tostring_default == obj)
   end
   ,
   testDefaultEqMetamethodObjectAndSameObjectAreEqual = function(self)
      local obj = self.class_tostring_default()
      luaunit.assertTrue(obj == obj)
   end
   ,
   testDefaultEqMetamethodObjectAndDifferentObjectAreEqual = function(self)
      local obj1 = self.class_tostring_default()
      local obj2 = self.class_tostring_default()
      luaunit.assertFalse(obj1 == obj2)
   end
   ,
   testDefaultEqMetamethodObjectAndDifferentClassObjectAreNotEqual = function(
         self)
      local obj1 = self.class_tostring_default()
      local obj2 = self.class_tostring_custom()
      luaunit.assertFalse(obj1 == obj2)
   end

}


TestSuperclasses = {

   setUp = function(self)
      self.superclass = plloop.create_class('SuperClass', {
         VAR = 'SUPER',
         LVL = 1,
         __add = function(self, other)
            return 'SuperClass __add'
         end,
         __sub = function(self, other)
            return 'SuperClass __sub'
         end,
         __mul = function(self, other)
            return 'SuperClass __mul'
         end
      })
      self.subclass = plloop.create_class('SubClass', {
         LVL = 2,
         __sub = function(self, other)
            return 'SubClass __sub'
         end,
         __mul = function(self, other)
            return 'SubClass __mul'
         end
      }, self.superclass)
      self.subsubclass = plloop.create_class('SubSubClass', {
         LVL = 3,
         __mul = function(self, other)
            return 'SubSubClass __mul'
         end
      }, self.subclass)
   end
   ,
   -- __superclass__ tests
   testSuperclassHasNoSuperclass = function(self)
      luaunit.assertIsNil(self.superclass.__superclass__)
   end
   ,
   testSubclassSuperclassIsSuperclass = function(self)
      luaunit.assertEquals(self.subclass.__superclass__, self.superclass)
   end
   ,
   testSubclassWithTableAsSuperclassHasNoSuperclass = function(self)
      local class = plloop.create_class('SuperClass', {}, {})
      luaunit.assertIsNil(class.__superclass__)
   end
   ,
   -- SuperClass tests
   testSuperclassVarAttr = function(self)
      luaunit.assertEquals(self.superclass.VAR, 'SUPER')
   end
   ,
   testSuperclassObjectVarAttr = function(self)
      local superobj = self.superclass()
      luaunit.assertEquals(superobj.VAR, 'SUPER')
   end
   ,
   testSuperclassLvlAttr = function(self)
      luaunit.assertEquals(self.superclass.LVL, 1)
   end
   ,
   testSuperclassObjectLvlAttr = function(self)
      local superobj = self.superclass()
      luaunit.assertEquals(superobj.LVL, 1)
   end
   ,
   testSuperclassAddMetamethod = function(self)
      local superobj = self.superclass()
      luaunit.assertEquals((superobj + 1), 'SuperClass __add')
   end
   ,
   testSuperclassSubMetamethod = function(self)
      local superobj = self.superclass()
      luaunit.assertEquals((superobj - 1), 'SuperClass __sub')
   end
   ,
   testSuperclassMulMetamethod = function(self)
      local superobj = self.superclass()
      luaunit.assertEquals((superobj * 1), 'SuperClass __mul')
   end
   ,
   -- SubClass tests
   testSubclassVarAttr = function(self)
      luaunit.assertEquals(self.subclass.VAR, 'SUPER')
   end
   ,
   testSubclassObjectVarAttr = function(self)
      local subobj = self.subclass()
      luaunit.assertEquals(subobj.VAR, 'SUPER')
   end
   ,
   testSubclassLvlAttr = function(self)
      luaunit.assertEquals(self.subclass.LVL, 2)
   end
   ,
   testSubclassObjectLvlAttr = function(self)
      local subobj = self.subclass()
      luaunit.assertEquals(subobj.LVL, 2)
   end
   ,
   testSubsubclassVarAttr = function(self)
      luaunit.assertEquals(self.subsubclass.VAR, 'SUPER')
   end
   ,
   testSubclassAddMetamethodInherited = function(self)
      local subobj = self.subclass()
      luaunit.assertEquals((subobj + 1), 'SuperClass __add')
   end
   ,
   testSubclassAddMetamethodOverloaded = function(self)
      local subobj = self.subclass()
      self.subclass.__add = function(self, other)
         return 'SubClass __add overloaded'
      end
      luaunit.assertEquals((subobj + 1), 'SubClass __add overloaded')
   end
   ,
   testSubclassSubMetamethod = function(self)
      local subobj = self.subclass()
      luaunit.assertEquals((subobj - 1), 'SubClass __sub')
   end
   ,
   testSubclassMulMetamethod = function(self)
      local subobj = self.subclass()
      luaunit.assertEquals((subobj * 1), 'SubClass __mul')
   end
   ,
   -- SubSubClass tests
   testSubsubclassObjectVarAttr = function(self)
      local subsubobj = self.subsubclass()
      luaunit.assertEquals(subsubobj.VAR, 'SUPER')
   end
   ,
   testSubsubclassLvlAttr = function(self)
      luaunit.assertEquals(self.subsubclass.LVL, 3)
   end
   ,
   testSubsubclassObjectLvlAttr = function(self)
      local subsubobj = self.subsubclass()
      luaunit.assertEquals(subsubobj.LVL, 3)
   end,
   testSubsubclassAddMetamethodInherited = function(self)
      local subsubobj = self.subsubclass()
      luaunit.assertEquals((subsubobj + 1), 'SuperClass __add')
   end
   ,
   testSubsubclassAddMetamethodOverloaded = function(self)
      self.subsubclass.__add = function(self, other)
         return 'SubSubClass __add overloaded'
      end
      local subsubobj = self.subsubclass()
      luaunit.assertEquals((subsubobj + 1), 'SubSubClass __add overloaded')
   end
   ,
   testSubsubclassSubMetamethodInherited = function(self)
      local subsubobj = self.subsubclass()
      luaunit.assertEquals((subsubobj - 1), 'SubClass __sub')
   end
   ,
   testSubsubclassSubMetamethodOverloaded = function(self)
      self.subsubclass.__sub = function(self, other)
         return 'SubSubClass __sub overloaded'
      end
      local subsubobj = self.subsubclass()
      luaunit.assertEquals((subsubobj - 1), 'SubSubClass __sub overloaded')
   end
   ,
   testSubsubclassMulMetamethod = function(self)
      local subsubobj = self.subsubclass()
      luaunit.assertEquals((subsubobj * 1), 'SubSubClass __mul')
   end

}


TestHelperFunctions = {

   setUp = function(self)
      self.class_one = plloop.create_class('ClassOne', {})
      self.class_two = plloop.create_class('ClassTwo', {})
   end
   ,
   testStringIsNotClass = function(self)
      luaunit.assertFalse(plloop.is_class('foo'))
   end
   ,
   testNumberIsNotClass = function(self)
      luaunit.assertFalse(plloop.is_class(1))
   end
   ,
   testNilIsNotClass = function(self)
      luaunit.assertFalse(plloop.is_class(nil))
   end
   ,
   testTrueIsNotClass = function(self)
      luaunit.assertFalse(plloop.is_class(true))
   end
   ,
   testFalseIsNotClass = function(self)
      luaunit.assertFalse(plloop.is_class(false))
   end
   ,
   testTableIsNotClass = function(self)
      luaunit.assertFalse(plloop.is_class({}))
   end
   ,
   testObjectIsNotClass = function(self)
      local obj = self.class_one()
      luaunit.assertFalse(plloop.is_class(obj))
   end
   ,
   testClassIsClass = function(self)
      luaunit.assertTrue(plloop.is_class(self.class_one))
   end
   ,
   testStringIsNotClassTwo = function(self)
      luaunit.assertFalse(plloop.is_class('foo', self.class_two))
   end
   ,
   testNumberIsNotClassTwo = function(self)
      luaunit.assertFalse(plloop.is_class(1, self.class_two))
   end
   ,
   testNilIsNotClassTwo = function(self)
      luaunit.assertFalse(plloop.is_class(nil, self.class_two))
   end
   ,
   testTrueIsNotClassTwo = function(self)
      luaunit.assertFalse(plloop.is_class(true, self.class_two))
   end
   ,
   testFalseIsNotClassTwo = function(self)
      luaunit.assertFalse(plloop.is_class(false, self.class_two))
   end
   ,
   testTableIsNotClassTwo = function(self)
      luaunit.assertFalse(plloop.is_class({}, self.class_two))
   end
   ,
   testObjectOneIsNotClassTwo = function(self)
      local obj = self.class_one()
      luaunit.assertFalse(plloop.is_class(obj, self.class_two))
   end
   ,
   testObjectTwoIsNotClassTwo = function(self)
      local obj = self.class_two()
      luaunit.assertFalse(plloop.is_class(obj, self.class_two))
   end
   ,
   testClassOneIsNotClassTwo = function(self)
      luaunit.assertFalse(plloop.is_class(self.class_one, self.class_two))
   end
   ,
   testClassTwoIsClassTwo = function(self)
      luaunit.assertTrue(plloop.is_class(self.class_two, self.class_two))
   end
   ,
   testStringIsNotObject = function(self)
      luaunit.assertFalse(plloop.is_object('foo'))
   end
   ,
   testNumberIsNotObject = function(self)
      luaunit.assertFalse(plloop.is_object(1))
   end
   ,
   testNilIsNotObject = function(self)
      luaunit.assertFalse(plloop.is_object(nil))
   end
   ,
   testTrueIsNotObject = function(self)
      luaunit.assertFalse(plloop.is_object(true))
   end
   ,
   testFalseIsNotObject = function(self)
      luaunit.assertFalse(plloop.is_object(false))
   end
   ,
   testTableIsNotObject = function(self)
      luaunit.assertFalse(plloop.is_object({}))
   end
   ,
   testClassIsNotObject = function(self)
      luaunit.assertFalse(plloop.is_object(self.class_one))
   end
   ,
   testObjectIsObject = function(self)
      local obj = self.class_one()
      luaunit.assertTrue(plloop.is_object(obj))
   end
   ,
   testClassIsNotInstanceOfSameClass = function(self)
      luaunit.assertFalse(plloop.instance_of(self.class_one, self.class_one))
   end
   ,
   testClassIsNotInstanceOfDifferentClass = function(self)
      luaunit.assertFalse(plloop.instance_of(self.class_one, self.class_two))
   end
   ,
   testClassObjectIsNotInstanceOfDifferentClass = function(self)
      local obj_one = self.class_one()
      luaunit.assertFalse(plloop.instance_of(obj_one, self.class_two))
   end
   ,
   testObjectIsNotInstanceOfSameObject = function(self)
      local obj_one = self.class_one()
      luaunit.assertFalse(plloop.instance_of(obj_one, obj_one))
   end
   ,
   testClassIsNotInstanceOfSameClassObject = function(self)
      local obj_one = self.class_one()
      luaunit.assertFalse(plloop.instance_of(self.class_one, obj_one))
   end
   ,
   testTableIsNotInstanceOfClass = function(self)
      luaunit.assertFalse(plloop.instance_of({}, self.class_one))
   end
   ,
   testTableIsNotInstanceOfSameTable = function(self)
      local tbl = {}
      luaunit.assertFalse(plloop.instance_of(tbl, tbl))
   end
   ,
   testNilIsNotInstanceOfNil = function(self)
      luaunit.assertFalse(plloop.instance_of(nil, nil))
   end
   ,
   testClassObjectIsInstanceOfSameClass = function(self)
      local obj_one = self.class_one()
      luaunit.assertTrue(plloop.instance_of(obj_one, self.class_one))
   end

}

os.exit(luaunit.LuaUnit.run())
