require 'yaml'
require 'digest/sha1'
require 'ftools'
require 'uri'
require 'net/https'

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
    t_url = @url
    uri = URI.parse(t_url)
    req = Net::HTTP::Get.new(uri.path + (uri.query ? "?#{uri.query}" : ''))
    req.basic_auth @username, @password
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"
    res = http.start {|http| http.request(req)}
    File.open(cache_file, 'w') do |f|
      f.write(res.body)
    end
  end

  def fetch_trac
    login_url = @url.gsub(/\?.*$/, '')
    login_url = (login_url[0,login_url.rindex('/') + 1] + 'login').to_s
    uri = URI.parse(login_url)
    http = Net::HTTP.new(uri.host, uri.port)
    cookie = nil
    http.start do |http|
      req = Net::HTTP::Get.new(uri.path)
      req.basic_auth @username, @password
      req['Cookie'] = cookie
      res = http.request(req)
      cookie = res['set-cookie'] || cookie
      trac_auth = cookie_val(cookie, 'trac_auth')

      uri = URI.parse(@url)
      req = Net::HTTP::Get.new(uri.path + '?' + uri.query)
      req.basic_auth @username, @password
      req['Cookie'] = cookie
      res = http.request(req)
      File.open(cache_file, 'w') do |f|
        f.write(res.body)
      end
    end
  end

  def expired?
    return true if !File.exists?(cache_file)
    (Time.now - File.mtime(cache_file)) > @@expire_time * 60
  end

  def cookie_val(cookie, key) 
    ret = nil
    return nil if cookie.nil?
    cookie.split(',').each do |token|
      token.split(';').each do |c|
        c.strip!
        single = c.split('=')
        if single.size==2 && single[0] == key
          ret = single[1]
        end
      end
    end
    ret
  end
end
