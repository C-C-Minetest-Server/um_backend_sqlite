-- um_backend_sqlite/src/cache.lua
-- Handle cache to avoid querying the DB too much
--[[
    um_backend_sqlite: Storing Unified Money data into a SQLite3 database
    Copyright (C) 2023-2024  1F616EMO

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
]]

-- Cache rules:
--- 1. Cache all online players; will be dropped after leaving + 2 minutes
--- 2. Put players into cache on access with a 2-minute timeout

local cache = {}
local ttl = {} -- in seconds
local mod = {}

local CACHE_TTL = 120

um_backend_sqlite.cache = {}
local _c = um_backend_sqlite.cache
local _db = um_backend_sqlite.database

-- Handle cache

function _c.set_cache(name)
    local bal = _db.get_balance(name)
    minetest.log("verbose", "[um_backend_sqlite] CACHE SET " .. name .. " " .. (bal or "nil"))
    if bal then
        cache[name] = bal
        ttl[name] = CACHE_TTL
        mod[name] = false
    end
end

function _c.write_cache(name)
    if cache[name] then
        local id = _db.get_primary_key(name)
        if id then
            _db.set_balance(id, name, cache[name])
        else
            _db.create_account(name, cache[name])
        end
        mod[name] = false
    end
end

function _c.wipe_cache(name)
    cache[name] = nil
    ttl[name] = nil
    mod[name] = nil
end

function _c.drop_cache(name)
    _c.write_cache(name)
    _c.wipe_cache(name)
end

function _c.commit_all()
    for name, _ in pairs(cache) do
        if mod[name] then
            _c.write_cache(name)
        end
    end
end

-- I/O on cache

function _c.get_balance(name)
    if not cache[name] then
        _c.set_cache(name)
    end
    return cache[name]
end

function _c.set_balance(name, balance)
    minetest.log("verbose", "[um_backend_sqlite] CACHE SETBAL " .. name .. " " .. balance)
    cache[name] = balance
    ttl[name] = CACHE_TTL
    mod[name] = true
end

-- Automatic read/drop cache

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    _c.set_cache(name)
end)

do
    local dt = 0
    minetest.register_globalstep(function(dtime)
        dt = dt + dtime
        if dt < 1 then return end
        dt = 0

        for name, t in pairs(ttl) do
            minetest.log("verbose", "[um_backend_sqlite] CACHE GS CHK " .. name .. " " .. t)
            if minetest.get_player_ip(name) then
                minetest.log("verbose", "[um_backend_sqlite] CACHE GS CHK ONLINE " .. name)
                ttl[name] = CACHE_TTL
            else
                minetest.log("verbose", "[um_backend_sqlite] CACHE GS CHK OFFLINE " .. name)
                if t <= 0 then
                    minetest.log("action", "[um_backend_sqlite] The TTL of " .. name .. " went below 0, dropping.")
                    _c.drop_cache(name)
                else
                    ttl[name] = t - 1
                end
            end
        end
    end)
end

do
    local function save()
        minetest.log("action", "[um_backend_sqlite] Dumping cache")
        _c.commit_all()
    end

    minetest.register_on_shutdown(function()
        save()
    end)

    local function loop()
        save()
        minetest.after(60, loop)
    end

    minetest.after(60, loop)
end