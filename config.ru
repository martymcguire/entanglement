require 'rubygems'
require 'sinatra'
require 'app'

root_dir = File.dirname(__FILE__)

Sinatra::Application.set(:views, File.join(root_dir, 'views'))
Sinatra::Application.set(:app_file, File.join(root_dir, 'app.rb'))
Sinatra::Application.set(:run, false)
Sinatra::Application.set(:environment, (ENV['RACK_ENV'] || 'production').to_sym)

run Sinatra::Application
