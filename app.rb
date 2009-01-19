require 'rubygems'
require 'sinatra'
require 'lib/feed'
require 'lib/authorization'
require 'nokogiri'
require 'yaml'

configure do
  ENTANGLE_CONFIG = YAML.load_file('config/config.yml')
  Feed.set_salt(ENTANGLE_CONFIG['salt']) if ENTANGLE_CONFIG['salt']
end

helpers do
  def repub_url(feed)
    "#{feed.id}.xml"
  end

  def edit_url(feed)
    "#{feed.id}"
  end

  def req_base
    @base_url ||= ENTANGLE_CONFIG['base_url']
    if (@base_url.nil? || @base_url == 'auto')
      "#{request.scheme}://#{request.host}#{request.port == 80 ? '' : ':' + request.port.to_s}"
    else
      @base_url
    end
  end

  def button(text, url, method = :get, _method = nil)
    haml :feed_button, :layout => false, :locals => { :text => text, :url => url, :method => method, :_method => _method }
  end

  include Sinatra::Authorization 
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
  redirect "."
end

# OPMLz
get "/opml.xml" do
  @feeds = Feed.all
  attachment 'entangled_feeds.xml'
  content_type 'application/xml'
  haml :opml, :layout => false
end

post "/opml" do
  u = params[:username]
  p = params[:password]
  t = params[:type]
  doc = Nokogiri::XML(params[:opml][:tempfile])
  doc.xpath('//outline').each do |entry|
    if entry['xmlUrl']
      Feed.new(:username => u, 
               :password => p, 
               :url => entry['xmlUrl'],
               :type => t).save
    end
  end
  redirect '.'
end

# Edit view
get "/:feed_id" do
  require_administrative_privileges
  @feed = Feed.find(params[:feed_id])
  if @feed.nil? 
    throw :halt, [404, 'Not Found']
  else
    haml :edit
  end
end

put "/:feed_id" do
  require_administrative_privileges
  @feed = Feed.find(params[:feed_id])
  if @feed.nil? 
    throw :halt, [404, 'Not Found']
  end
  @feed.update_attributes(params[:feed])
  @feed.save
  redirect "#{@feed.id}"
end
  
delete "/:feed_id" do
  require_administrative_privileges
  @feed = Feed.find(params[:feed_id])
  if @feed.nil? 
    throw :halt, [404, 'Not Found']
  end
  @feed.destroy
  redirect "."
end

get "/:feed_id.xml" do
  @feed = Feed.find(params[:feed_id])
  if @feed.nil? 
    throw :halt, [404, 'Not Found']
  end
  content_type 'application/xml', :charset => 'utf-8'
  @feed.content
end

get "/:feed_id" do
  @f = Feed.find(params[:feed_id])
  haml :feed
end

get "/public/styles.css" do
  content_type 'text/css', :charset => 'utf-8'
  sass :styles
end

