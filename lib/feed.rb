require 'yaml'
require 'digest/sha1'
require 'ftools'
require 'net/https'
require 'uri'

class Feed
  @@feeds_path = 'data'
  @@cache_path = 'cache'
  @@salt = 'pr372l5_4ND_hUmMu5'
  @@expire_time = 30 # minutes

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
    # TODO: fixme to use real basic auth
    req = Net::HTTP::Get.new(uri.path + (uri.query ? "?#{uri.query}" : ''))
    req.basic_auth @username, @password
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"
    res = http.start {|http| http.request(req)}
    File.open(cache_file, 'w') do |f|
      f.write(res.body)
    end
  end

  def expired?
    return true if !File.exists?(cache_file)
    (Time.now - File.mtime(cache_file)) > @@expire_time * 60
  end
end
