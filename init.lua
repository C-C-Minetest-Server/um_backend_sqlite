-- um_backend_sqlite/init.lua
-- Storing Unified Money data into a SQLite3 database
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

um_backend_sqlite = {}
um_backend_sqlite.internal = {}

local ie = minetest.request_insecure_environment()
if not ie then
    error("[um_backend_sqlite] Please add um_backend_sqlite into secure.trusted mod.")
end

um_backend_sqlite.internal.sqlite3 = ie.require("lsqlite3")
if minetest.global_exists("sqlite3") then sqlite3 = nil end

local MP = minetest.get_modpath("um_backend_sqlite")
for _, name in ipairs({
    "db",
    "cache",
    "api",
}) do
    dofile(MP .. "/src/" .. name .. ".lua")
end

um_backend_sqlite.internal = nil
