require 'rubygems'
require 'sinatra'
require 'dm-migrations'
require 'dm-core'
require 'digest/sha1'
require 'chronic'
require 'dm-postgres-adapter'
require './app.rb'
run Sinatra::Application
$stdout.sync = true
