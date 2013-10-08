local M = {}

local sqlite = require 'sqlite3'
local vent = require 'vendor.vent.vent'
local log = require 'vendor.log.log'

function M.__call(t, ...)
	assert(M.inited, 'Please call config.init first')
	local args = {...}

	if args[1] == 'schemaVersion' then
		if #args == 2 then
			local arg = type(args[2]) == 'number' and args[2] or tonumber(args[2])
			M.db:exec('PRAGMA user_version='..arg)
			return true

		elseif #args == 1 then
			local stmt = M.db:prepare('PRAGMA user_version')
			assert(stmt, 'error while preparing user_version')

			local step = stmt:step()
			assert(step == sqlite.ROW, 'error while retrieving user_version')
			local ret = stmt:get_value(0)
			stmt:finalize()
			return ret
		end
	end

	if #args == 2 then
		local key, value = unpack(args)
		local stmt, _

		stmt = M.db:prepare "UPDATE yogoconfig SET value=:value WHERE key=:key"
		assert(stmt, 'Failed to prepare config-update statement')

		_ = stmt:bind_names{value = tostring(value), key = key}
		assert(_ == sqlite.OK, 'Failed to bind config-update statement')

		_ = stmt:step()
		assert(_ == sqlite.DONE, 'Failed to update config-update statement')

		stmt:finalize()
		stmt = nil

		if M.db:changes() == 0 then
			stmt = M.db:prepare "INSERT INTO yogoconfig(key, value) VALUES (:key, :value)"
			assert(stmt, 'Failed to prepare config-insert statement')

			local _ = stmt:bind_names({value = tostring(value), key = key})
			assert(_ == sqlite.OK, 'Failed to bind config-insert statement')

			_ = stmt:step()
			assert(_ == sqlite.DONE, 'Failed to insert config-insert statement')

			stmt:finalize()
			stmt = nil
		end

	elseif #args == 1 then
		local stmt, _

		stmt = M.db:prepare "SELECT value FROM yogoconfig where key=?"
		assert(stmt, 'Failed to prepare config-select statement')

		_ = stmt:bind_values(args[1])
		assert(_ == sqlite.OK, 'Failed to bind parameter on config-select statement')

		_ = stmt:step()
		if _ == sqlite.DONE then
			stmt:reset()
			stmt:finalize()
			return nil
		elseif _ == sqlite.ROW then
			local ret = stmt:get_value(0)
			stmt:finalize()
			if ret == 'true' then
				return true
			elseif ret == 'false' then
				return false
			elseif ret == 'nil' then
				return nil
			end
			return ret
		else
			error('Failed to retrieve value from config-select statement')
		end
	else
		--print('0 or more than 2 values passed to config')
		return 
	end
end

function M.queryColumn(column, sql)
	local ret = nil
	for row in M.db:nrows(sql) do
		ret = row[column]
	end
	return ret
end

function M.exec(sql, args)
	local ret
	if not args then
		ret = M.db:exec(sql)
		assert(ret == sqlite3.OK, '[SQL] Failed('..ret..'): ' .. sql)
	else
		local stmt = M.db:prepare(sql)
		assert(type(args) == 'table', 'expected parameter args to be a table')

		if #args > 0 then
			stmt:bind_values(unpack(args))
		end
		ret = stmt:step()
		assert(ret == sqlite3.DONE, '[SQL] failed to execute sql ' .. ret)
	end
end

function M.init(settings)
	settings = settings or {}
	M.name = settings.name or 'config'
	M.location = settings.location or system.DocumentsDirectory
	M.debug = settings.debug or false

	local path = system.pathForFile(M.name .. '.sqlite', M.location)
	M.db = sqlite3.open( path )
	if M.debug then
		M.db:trace(function(udata, sql)
			log('[SQL] ' .. sql)
		end, {})
	end

	local stmt = M.db:prepare("SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = 'yogoconfig'")
	local step = stmt:step()
	assert(step == sqlite.ROW, 'Failed to detect if schema already exists')

	M.inited = true
	if stmt:get_value(0) == 0 then
		log '[config] Creating config'
		local exec = M.db:exec "CREATE TABLE yogoconfig (key VARCHAR UNIQUE, value VARCHAR);"
		assert(exec == sqlite.OK, 'There was an error creating the schema')
		vent:trigger('createdConfig')
	end
	vent:trigger('initedConfig')
end

M.__index = M

local function onSystemEvent( event )
	if event.type == "applicationExit"  then
		if M.db and M.db:isopen() then
			M.db:close()
			M.db = nil
		end
	end
end
Runtime:addEventListener('system', onSystemEvent)

return setmetatable({}, M)
