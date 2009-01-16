require 'rubygems'
require 'sinatra'
require 'lib/feed'

get "/" do
  haml :index
end

get "/feed/:feed_id" do
  content_type 'application/xml', :charset => 'utf-8'
  Feed.find(params[:feed_id]).content
end

get "/public/styles.css" do
  sass :styles
end
