require 'rubygems'
require 'sinatra'

get "/" do
  haml :index
end

get "/public/styles.css" do
  sass :styles
end
