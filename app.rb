require 'rubygems'
require 'sinatra'
require 'lib/feed'
require 'lib/authorization'

helpers do
  def repub_url(feed)
    "/#{feed.id}.xml"
  end

  def edit_url(feed)
    "/#{feed.id}"
  end

  def req_base
    "#{request.scheme}://#{request.host}#{request.port == 80 ? '' : ':' + request.port.to_s}"
  end

  def button(text, url, method = :get, _method = nil)
    haml :feed_button, :layout => false, :locals => { :text => text, :url => url, :method => method, :_method => _method }
  end

  include Sinatra::Authorization 
end

# Parse params Rails-style
# http://sinatra.rubyforge.org/book.html#handling_of_rails_like_nested_params
before do
  new_params = {}
  params.each_pair do |full_key, value|
    this_param = new_params
    split_keys = full_key.split(/\]\[|\]|\[/)
    split_keys.each_index do |index|
      break if split_keys.length == index + 1
      this_param[split_keys[index]] ||= {}
      this_param = this_param[split_keys[index]]
   end
   this_param[split_keys.last.to_sym] = value
  end
  request.params.replace new_params
end

# Feeds control panel thing
get "/" do
  require_administrative_privileges
  @feeds = Feed.all
  haml :index
end

post "/" do
  require_administrative_privileges
  @feed = Feed.new(params[:feed])
  @feed.save
  redirect "/"
end

# OPMLz
get "/opml.xml" do
  @feeds = Feed.all
  content_type 'application/xml', :charset => 'utf-8'
  haml :opml, :layout => false
end

# Edit view
get "/:feed_id" do
  require_administrative_privileges
  @feed = Feed.find(params[:feed_id])
  haml :edit
end

put "/:feed_id" do
  require_administrative_privileges
  @feed = Feed.find(params[:feed_id])
  @feed.update_attributes(params[:feed])
  @feed.save
  redirect "/#{@feed.id}"
end
  
delete "/:feed_id" do
  require_administrative_privileges
  @feed = Feed.find(params[:feed_id])
  @feed.destroy
  redirect "/"
end

get "/:feed_id.xml" do
  content_type 'application/xml', :charset => 'utf-8'
  Feed.find(params[:feed_id]).content
end

get "/:feed_id" do
  @f = Feed.find(params[:feed_id])
  haml :feed
end

get "/public/styles.css" do
  content_type 'text/css', :charset => 'utf-8'
  sass :styles
end

