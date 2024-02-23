-- um_backend_sqlite/src/db.lua
-- Handle database I/O
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

local WP = minetest.get_worldpath()
local MP = minetest.get_modpath("um_backend_sqlite")
local _int = um_backend_sqlite.internal
local _sql = _int.sqlite3

local db = _sql.open(WP .. "/um_backend_sqlite.sqlite")
if not db then
    error("[um_backend_sqlite] Failed to open the database. Please check file permissions.")
end
_int.db = db

function _int.db_exec(stmt)
    if db:exec(stmt) ~= _sql.OK then
        local errmsg = db:errmsg()
        if errmsg ~= "not an error" then
            minetest.log("warning", "[um_backend_sqlite] Sqlite ERROR: " .. errmsg)
            return false, errmsg
        end
    end
    return true
end

function _int.db_prepare(sql)
    local q, err = db:prepare(sql)
    if err ~= "" and err ~= _sql.OK then
        local errmsg = db:errmsg()
        if errmsg ~= "not an error" then
            minetest.log("warning", "[um_backend_sqlite] Sqlite Prepare ERROR: " .. errmsg)
            return false, errmsg
        end
    end
    return q
end

function _int.stmt_exec(stmt)
    local state = stmt:step()
    if state ~= _sql.DONE and state ~= _sql.ROW then
        local errmsg = db:errmsg()
        if errmsg ~= "not an error" then
            minetest.log("warning", "[um_backend_sqlite] Sqlite ERROR: " .. errmsg)
            return false, errmsg
        end
    end

    return true, state
end

do
    -- Load initial schema
    local f = assert(io.open(MP .. "/schema.sql"))
    local q = f:read("*a")

    if not _int.db_exec(q) then
        error("[um_backend_sqlite] Failed to load initial schema")
    end
end

um_backend_sqlite.database = {}
local _db = um_backend_sqlite.database

function _db.get_primary_key(name)
    local q = assert(_int.db_prepare([[
        SELECT `id` from `um_balance`
        WHERE `name` = ?;
    ]]))
    q:bind(1, name)

    for row in q:urows() do -- luacheck: ignore 512
        return row
    end
end

function _db.set_balance(id, value)
    local q = assert(_int.db_prepare([[
        UPDATE `um_balance`
        SET `balance` = ?
        WHERE `id` = ?;
    ]]))
    q:bind(1, value)
    q:bind(2, id)

    return _int.stmt_exec(q)
end

function _db.create_account(name, value)
    local q = assert(_int.db_prepare([[
        INSERT INTO `um_balance`
        (`name`, `balance`) VALUES (?, ?);
    ]]))
    q:bind(1, name)
    q:bind(2, value)

    return _int.stmt_exec(q)
end

function _db.get_balance(name)
    local q = assert(_int.db_prepare([[
        SELECT `balance` from `um_balance`
        WHERE `name` = ?;
    ]]))
    q:bind(1, name)

    for row in q:urows() do -- luacheck: ignore 512
        return row
    end
end

function _db.del_account(name)
    local q = assert(_int.db_prepare([[
        DELETE FROM `um_balance`
        WHERE `name` = ?;
    ]]))
    q:bind(1, name)

    return _int.stmt_exec(q)
end

function _db.list_accounts()
    local q = assert(_int.db_prepare([[
        SELECT `name` FROM `um_balance`;
    ]]))

    local r = {}
    for row in q:urows() do
        r[#r+1] = row
    end

    return r
end
