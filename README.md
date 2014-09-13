Overview
========

Documentation
-----

[http://rubygems.org/gems/namecheap](http://rubygems.org/gems/namecheap)

Usage
-----

In your initializers, configure Namecheap like so:

```ruby
Namecheap.configure do |config|
  config.key = 'apikey'
  config.username = 'apiuser'
  config.client_ip = '127.0.0.1'
  config.endpoint = 'https://api.sandbox.namecheap.com/xml.response'
  # config.endpoint = 'https://api.namecheap.com/xml.response'
end
```

Then you can do something like:

```ruby
Namecheap.domains.get_list
```

Please see the Namecheap API documentation for more information

About this project
-------------

Namecheap is a ruby wrapper for the [Namecheap API](http://developer.namecheap.com/docs/doku.php?id=api-reference:index)

The code was originally forked from https://github.com/hashrocket/namecheap

At [Mindvalley](http://www.mindvalley.com) (the company I work for) we have something
called 'HackdayFridays' where we spend the whole day hacking on an interesting
project that may or may not be directly related to the business. It was enacted
so that the tech and production team can unwind from what can be a monotonous
work week, and hack on something more interesting.

One of the proposed projects was a 'big red button' where someone can just type
in the domain name, push a big red button, and magically:

* the domain name is purchased
* the DNS is pointed to our load balancer
* a subversion repository is created (with users)
* a template is committed to the repository with default pages
* a project is created in webistrano
* the initial setup and deployment is done

Mostly everything is already automated except the domain name purchase and dns.
We purchase most of our domains from Namecheap (and some from GoDaddy) and it was
fortunate that Namecheap has an API. Unfortunately there didn't seem to be a gem
that already existed.

A search brought me to HashRocket's namecheap API wrapper. It didn't have any of
the purchase API wrappers, but it was a good starting point (and allowed me to
study how seasoned pros would approach API wrappers). So I forked, published a
gem based on the fork, and hacked on it. And that's how it all began :)

Credits
-------

Tristan V. Gomez: tristan dot gomez at gmail dot com

[Hashrocket](http://www.hashrocket.com/) from where the original code was forked from

[Mongoid](http://www.mongoid.org) from where the configuration code was modified from


Plug!!
------

Mindvalley is [hiring](http://www.mindvalley.com/careers) :)

License
-------

Copyright (c) 2011 Tristan V. Gomez

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
