# dbconfig

## Installation

Download the release zip from [the releases tab](https://github.com/jeduan/corona-dbconfig/releases)
and drop it on your project

## Usage

```lua
local config = require 'vendor.dbconfig.dbconfig'

config.init()

config('key', 'value')
```

### config.init

Calling `config.init` is required before config. It is suggested to be called within your `main.lua` file

It takes a table with the following options

 - `debug` (default false) set to true to log all database queries

and either

 - `name` (default config) the name of the database
 - `location` (default system.DocumentsDirectory) the location of the database

or

 - `db` an already initialized sqlite db object. This ignores `name` and `location`

 
```lua
local config = require 'vendor.dbconfig.dbconfig'

config.init({
  name = 'config',
  debug = true
})

config('key', 'value')
-- or
config{key = 'value'}
```
Please note that all values are converted to strings

## aditional methods

dbconfig includes some aditional utility methods for querying databases

### config.exec

`config.exec(sql[, args])` executes an SQL query. if args is provided it binds the table names.

```lua
local sql = "UPDATE contacts SET company=:company WHERE name=:name"
local params = {
	company = 'Foo Enterprises'
	name = 'John Doe'
}
config.exec(sql, params)
```

### config.lastInsertId

`config.lastInsertId` will return the rowid of the last inserted row

```lua
local sql = "INSERT INTO contacts (name) VALUES ('John Smith')"
config.exec(sql)
local id = config.lastInsertId()
```

### config.queryColumn

`config.queryColumn` will return a specific column of an sql query

```lua
local sql = "SELECT name FROM contacts"
local name = config.queryColumn('name', sql)
```

### config.queryTable

`config.queryTable` will return a table with the named results of a query

```lua
local sql = "SELECT name FROM contacts"
local contacts = config.queryTable(sql)
```
