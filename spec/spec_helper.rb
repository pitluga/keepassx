require 'simplecov'
require 'rspec'
require 'respect'
require 'factory_bot'

# Start Simplecov
SimpleCov.start do
  add_filter 'spec/'
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

  # disable monkey patching
  # see: https://relishapp.com/rspec/rspec-core/v/3-8/docs/configuration/zero-monkey-patching-mode
  config.disable_monkey_patching!
end

# Configure/Patch Respect
module RespectPatch
  def validate_uuid(uuid)
    return true if uuid =~ /\A[0-9a-f]{32}\z/i
    raise Respect::ValidationError, "invalid UUID"
  end
end

module UUIDValidator
  def uuid(name, options = {})
    string(name, { format: :uuid  }.merge(options))
  end
end

Respect::FormatValidator.prepend(RespectPatch)
Respect.extend_dsl_with(UUIDValidator)


# Load lib
require 'keepassx'
require_relative 'support/factories'

FIXTURE_PATH          = File.expand_path File.join(File.dirname(__FILE__), 'fixtures')
TEST_DATABASE_PATH    = File.join(FIXTURE_PATH, 'database_test.kdb')
EMPTY_DATABASE_PATH   = File.join(FIXTURE_PATH, 'database_empty.kdb')
KEYFILE_DATABASE_PATH = File.join(FIXTURE_PATH, 'database_with_key.kdb')
