# log-tools

## Installation

Ensure the bower registry is `"https://yogome-bower.herokuapp.com"` and then `bower install dbconfig`

## Usage

```lua
local config = require 'vendor.dbconfig.dbconfig'

config.init()

config('key', 'value')
```

### config.init

Calling `config.init` is required before config. It is suggested to be called within your `main.lua` file

It takes a table with the following options

 - `name` (default config) the name of the database
 - `location` (default system.DocumentsDirectory) the location of the database
 - `debug` (default false) set to true to log all database queries
 
```lua
local config = require 'vendor.dbconfig.dbconfig'

config.init{
	name = 'config',
	debug = true
}

config('key', 'value')
```

Please note that all values are converted to strings