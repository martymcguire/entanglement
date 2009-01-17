# From "Sinatra Basic Authentication - Selectively Applied"
# http://www.gittr.com/index.php/archive/sinatra-basic-authentication-selectively-applied/

require 'htauth'

module Sinatra
  module Authorization

  def passwd_file
    "data/.htpasswd"
  end

  def auth
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
  end

  def unauthorized!(realm="Entangle (of pizza)")
    header 'WWW-Authenticate' => %(Basic realm="#{realm}")
    throw :halt, [ 401, 'Authorization Required' ]
  end

  def bad_request!
    throw :halt, [ 400, 'Bad Request' ]
  end

  def authorized?
    request.env['REMOTE_USER']
  end

  def authorize(username, password)
    # Insert your logic here to determine if username/password is good
    return false if !File.exists?(passwd_file)
    pf = HTAuth::PasswdFile.new(passwd_file)
    user = pf.fetch(username)
    !user.nil? && user.authenticated?(password)
  end

  def require_administrative_privileges
    return if authorized?
    unauthorized! unless auth.provided?
    bad_request! unless auth.basic?
    unauthorized! unless authorize(*auth.credentials)
    request.env['REMOTE_USER'] = auth.username
  end

  def admin?
    authorized?
  end

  end
end

