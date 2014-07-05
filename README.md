# Keepassx

This is fork of Tony Pitluga's Ruby API for [keepassx](http://www.keepassx.org/) with read-write support.

## Installation

```
gem install ruby-keepassx
```
or if you use bundler

```ruby
gem 'ruby-keepassx'
```

## Usage

```ruby
require 'keepassx'

database = Keepassx::Database.open("/path/to/database.kdb")
database.unlock("the master password")
puts database.entry("entry's title").password
```

## Security Warning

No attempt is made to protect the memory used by this library; there may be something we can do with libgcrypt's secure-malloc functions, but right now your master password is unencrypted in ram that could possibly be paged to disk.
