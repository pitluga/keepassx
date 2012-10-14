$:.unshift File.expand_path('../../lib', __FILE__)
require 'keepassx'
require 'rspec'

TEST_DATABASE_PATH = File.expand_path('../test_database.kdb', __FILE__)
