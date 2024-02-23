-- um_backend_sqlite/src/api.lua
-- Handle um_core registeration
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

local _c = um_backend_sqlite.cache
local _db = um_backend_sqlite.database

unified_money.register_backend({
    get_balance = function(name)
        return _c.get_balance(name)
    end,
    set_balance = function(name, val, forced)
        if not forced then
            if not _db.get_primary_key(name) then return false end
        end
        _c.set_balance(name, val)
        return true
    end,
    create_account = function(name, default_val)
        _db.create_account(name, default_val or 0)
        _c.set_balance(name, default_val or 0)
        return true
    end,
    delete_account = function(name)
        _c.wipe_cache(name)
        return _db.del_account(name)
    end,
    -- Check whether an account exists
    account_exists = function(name)
        return _db.get_primary_key(name) and true or false
    end,
    list_accounts = function()
        -- Ensure the list returned by the DB is accuriate
        _c.commit_all()
        return _db.list_accounts()
    end,
    canonical_name = function(name)
        return name
    end,
})