Entanglement - an RSS proxy for authenticated feeds
===================================================

Entanglement is a simple Sinatra-based RSS proxy system to ease access to RSS 
feeds protected by HTTP Basic Authentication, and RSS feeds that can "misbehave"
(such as password-protected Trac Timeline feeds.  It was written to scratch an 
itch about Google Reader, which does not support any kind of authenticated feed.

The basic premise is that you enter your feed URLs and credentials into 
Entanglement, which will provide a new, non-authenticated feed URL that you can 
enter into your non-auth-friendly RSS reader (for example, Google Reader).

Overview
--------

* You can add feed information (URL, username, password, authentication type) 
  via the management form on the main page, or upload an OPML file to add 
  several feeds with the same username/password/type.
* Your feeds' URLs, usernames, and passwords are used to create a SHA1 digest 
  which acts as the ID for that feed.
* Entanglement exports an OPML file for you to load in your favorite 
  misbehaving RSS reader.
* Feed configuration is stored locally in YAML files (which you should make sure
  are readable only by you).
* Feed management is protected by Basic Authentication, with access controlled 
  via a simple `.htaccess` file.  
* A 30-minute local filesystem cache is used to keep traffic reasonable.
* Be sure to protect the non-authenticated URLs provided by Entanglement.  If 
  you do hand out a URL that you didn't want to, you can change the URL for all
  feeds by changing the value of `@@salt` in `lib/feed.rb`, though you will have
  to delete and re-add all of your feeds.

Deployment
----------

Required Gems:

* [Sinatra](http://github.com/bmizerany/sinatra/tree/master)
  * Tested with version 0.9.0.2, also requires [Thin](http://github.com/macournoyer/thin/tree/master)
* [HAML](http://github.com/nex3/haml/tree/master)
  * Tested w/2.0.6
* [Nokogiri](http://github.com/tenderlove/nokogiri/tree/master)
  * Tested w/ 1.1.1
* [HTAuth](http://github.com/copiousfreetime/htauth/tree/master)
  * Tested w/ 1.0.3

Deployment Steps

1. Clone this project to the deployment machine
2. Copy `config/config.yml.example` to `config/config.yml` and edit it to your
   liking.  Make sure the value for `salt` is unique!
3. Create the `.htpaswd` file

    $ htpasswd -c data/.htpasswd <username>

4. Test things out with Sinatra and visit `http://localhost:4567/` with your 
   browser:

    $ ruby app.rb

5. Deploy in your favorite manner.  For instance, with [Phusion Passenger](http://www.modrails.com/documentation/Users%20guide.html#_deploying_a_rack_based_ruby_application)

Authors
-------

* Robert McGuire <schmartissimo@gmail.com>

Credits
-------

Logo derived from
[RSS-vector.psd](http://www.readydone.com/files/RSS-vector.psd), 
found on the article 
[Create a Vector RSS Icon with Illustrator](http://www.blog.spoongraphics.co.uk/tutorials/create-a-vector-rss-icon-with-illustrator).

OPML icon from [http://opmlicons.com/](http://opmlicons.com/)

License
-------

    The MIT License

    Copyright &copy; 2009 Robert McGuire

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.

