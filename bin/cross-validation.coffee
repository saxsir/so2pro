#! /usr/bin/env node_modules/coffee-script/bin/coffee
args = process.argv
path = require 'path'

Classifier = require '../src/Classifier'
configPath = path.resolve(args[2])
config = require configPath

Classifier.run config, args[3].split(','), args[4].split(',')