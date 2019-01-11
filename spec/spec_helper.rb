require 'simplecov'
require 'rspec'
require 'respect'
require 'factory_bot'

# Start Simplecov
SimpleCov.start do
  add_filter '/spec/'
end

# Configure RSpec
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.color = true
  config.fail_fast = false

  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# Load lib
require 'keepassx'
require_relative 'factories'

FIXTURE_PATH          = File.expand_path File.join(File.dirname(__FILE__), 'fixtures')
TEST_DATABASE_PATH    = File.join(FIXTURE_PATH, 'database_test.kdb')
EMPTY_DATABASE_PATH   = File.join(FIXTURE_PATH, 'database_empty.kdb')
KEYFILE_DATABASE_PATH = File.join(FIXTURE_PATH, 'database_with_key.kdb')


module RespectPatch
  def self.included(base)
    base.send(:prepend, InstanceMethods)
  end

  module InstanceMethods

    def validate_uuid(uuid)
      return true if uuid =~ /\A[0-9a-f]{32}\z/i
      raise Respect::ValidationError, "invalid UUID"
    end

  end
end

module UUIDValidator
  def uuid(name, options = {})
    string(name, { format: :uuid  }.merge(options))
  end
end

unless Respect::FormatValidator.included_modules.include?(RespectPatch)
  Respect::FormatValidator.send(:include, RespectPatch)
end

Respect.extend_dsl_with(UUIDValidator)
