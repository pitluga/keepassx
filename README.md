## Keepassx

[![GitHub license](https://img.shields.io/github/license/n-rodriguez/keepassx.svg)](https://github.com/n-rodriguez/keepassx/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/n-rodriguez/keepassx.svg)](https://github.com/n-rodriguez/keepassx/releases/latest)
[![Build Status](https://travis-ci.org/n-rodriguez/keepassx.svg?branch=master)](https://travis-ci.org/n-rodriguez/keepassx)
[![Code Climate](https://codeclimate.com/github/n-rodriguez/keepassx/badges/gpa.svg)](https://codeclimate.com/github/n-rodriguez/keepassx)
[![Test Coverage](https://codeclimate.com/github/n-rodriguez/keepassx/badges/coverage.svg)](https://codeclimate.com/github/n-rodriguez/keepassx/coverage)
[![Dependency Status](https://gemnasium.com/n-rodriguez/keepassx.svg)](https://gemnasium.com/n-rodriguez/keepassx)

### A Ruby library to read and write [KeePassX](http://www.keepassx.org/) databases.

## Installation

```sh
gem install keepassx
```

or if you use bundler

```ruby
gem 'keepassx'
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
