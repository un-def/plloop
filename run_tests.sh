#!/bin/sh

for LUA in lua5.1 lua5.2 lua5.3
do
    echo -n "::: Testing with $LUA"
    LUA_BIN=$(which $LUA)
    if [ -z "$LUA_BIN" ]
    then
        echo " :::\nLua interpreter not found"
    else
        echo " ($LUA_BIN) :::"
        eval $LUA_BIN tests.lua
    fi
    echo "\n====================\n"
done
