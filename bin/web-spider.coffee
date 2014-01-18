#! /usr/bin/env node_modules/coffee-script/bin/coffee
args = process.argv
path = require 'path'

WebSpider = require '../src/WebSpider'
configPath = path.resolve(args[2])
config = require configPath
WebSpider.run config