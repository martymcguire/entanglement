require 'yaml'
require 'digest/sha1'
require 'ftools'
require 'uri'
require 'open-uri'
require 'nokogiri'

class Feed
  @@feeds_path = 'data'
  @@cache_path = 'cache'
  @@salt = 'pr3tz3l2_4Nd-Hum/\/\|_|5'
  @@expire_time = 30 # minutes

  def self.set_salt(salt)
    @@salt = salt
  end

  attr_accessor :url
  attr_accessor :username
  attr_accessor :password
  attr_accessor :type

  def initialize(opts = {})
    @url = opts[:url]
    @username = opts[:username]
    @password = opts[:password]
    @type = opts[:type] || :basic
    @filename = opts[:filename]
  end

  def update_attributes(opts = {})
    @url = opts[:url]
    @username = opts[:username]
    @password = opts[:password]
    @type = opts[:type] || :basic
  end

  def id
    @filename.gsub(/\.yml/, '') if @filename
  end

  def self.find(id)
    return nil if !File.exists?(file_path("#{id}.yml"))
    YAML.load_file(file_path("#{id}.yml"))
  end

  def self.all
    Dir.entries(@@feeds_path).select{|f| f =~ /\.yml$/}.map do |f|
      YAML.load_file(file_path(f))
    end
  end

  def save
    File.safe_unlink(Feed.file_path(@filename)) if @filename
    @filename = filename
    # save the file
    File.open(Feed.file_path(@filename), 'w') do |f|
      f.write(self.to_yaml)
    end
  end

  def destroy
    File.safe_unlink(Feed.file_path(@filename)) if @filename
  end

  def filename
    Digest::SHA1.hexdigest("#{@url}_#{@username}_#{@password}_#{@type}-#{@@salt}")+'.yml'
  end

  def self.file_path(filename)
    File.join(@@feeds_path, filename)
  end

  def feedfile
    id+'.xml'
  end

  def self.feed_path(filename)
    File.join(@@cache_path, filename)
  end

  def cache_file
    Feed.feed_path(feedfile)
  end

  def content
    if expired?
      send("fetch_#{type}".to_sym)
    end
    File.open(cache_file, 'r').read
  end

  def fetch_basic
    open(@url, :http_basic_authentication => [@username, @password]) do |u|
      File.open(cache_file, 'w') do |f|
        u.each_line {|l| f.write(l) }
      end
    end
  end

  def fetch_trac
    # Try to fetch the feed.  It'll 403 (throwing HTTPError), but still return
    # a page with a login url!
    login_url = nil
    begin
      open(@url)
    rescue OpenURI::HTTPError => e
      doc = Nokogiri::HTML(e.io)
      login_url = doc.xpath("//a[contains(@href, '/login')]").first["href"].to_s
      if(login_url.index('/') == 0)  # starts with '/'
        uri = URI.parse(@url)
        login_url = "#{uri.scheme}://#{uri.host}#{(uri.port != uri.default_port) ? ':' + uri.port.to_s : ''}#{login_url}"
      end
    end
    cookie = nil
    # Now that we have the login URL, log into it and get the cookie back
    # Will still throw a 403...
    http = Net::HTTP.new(uri.host, uri.port)
    uri = URI.parse(login_url)
    http.use_ssl = true if uri.scheme == "https"
    req = Net::HTTP::Get.new(uri.path)
    req.basic_auth @username, @password
    req['Cookie'] = cookie
    res = http.request(req)
    cookie = res['set-cookie'] || cookie
    
    # Finally fetch the feed, passing both the cookie and auth back
    http = Net::HTTP.new(uri.host, uri.port)
    uri = URI.parse(@url)
    req = Net::HTTP::Get.new(uri.path + '?' + uri.query)
    req.basic_auth(@username, @password)
    req['Cookie'] = cookie
    res = http.request(req)
    File.open(cache_file, 'w') { |f| f.write(res.body)}
  end

  def expired?
    return true if !File.exists?(cache_file)
    (Time.now - File.mtime(cache_file)) > @@expire_time * 60
  end
end
