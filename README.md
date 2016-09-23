Overview
========

There are three parts to this gem:

* Support - contains the various support objects such as exceptions, url builder, and HTTP connectivity.

* Thin client - a very thin wrapper around the namecheap API. This aims to mirror the API documentation closely to make it easy to update the gem whenever the API changes.

* OOP client - an Object-oriented layer that composes functionality from the thin client, so you can have conveniences such as `namecheap.is_domain_available? 'hashrocket.com' # => false`

Documentation
-----

[http://rubygems.org/gems/namecheap](http://rubygems.org/gems/namecheap)

This is the branch for the rewrite of the Namecheap gem.

While efforts will be made to retain many of the concepts of the previous version,
please expect that this version will NOT be backawards compatible.

Usage
-----

```
namecheap = Namecheap::API::Client.new(
  api_user: user,
  api_key: key,
  user_name: name, # optional, defaults to api_user
  client_ip: ip # optional, defaults to the current server's ip
)

namecheap.domains.get_contacts(domain_name: "parasquid.com")
```