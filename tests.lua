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


os.exit(luaunit.LuaUnit.run())
