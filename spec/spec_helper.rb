$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'keepassx'
require 'rspec'
require 'yaml'
require 'respect'


RSpec.configure do |config|
  # ...
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end


FIXTURE_PATH = File.expand_path(File.join File.dirname(__FILE__), 'fixtures')
TEST_DATABASE_PATH = File.join FIXTURE_PATH, '../fixtures/test_database.kdb'
NEW_DATABASE_PATH = File.join FIXTURE_PATH, '../fixtures/new_database.kdb'

shared_context :keepassx do

  # require 'coveralls'
  # Coveralls.wear!

  before :all do
    @test_db = Keepassx.open TEST_DATABASE_PATH

    File.delete NEW_DATABASE_PATH if File.exist? NEW_DATABASE_PATH
    @new_db = Keepassx.new NEW_DATABASE_PATH

    # @data_array_db = Keepassx::Database.new data_array
  end


  let :data_array do
    YAML.load File.read File.join FIXTURE_PATH, 'test_data_array.yaml'
  end


  let :original_data_array do
    YAML.load File.read File.join FIXTURE_PATH, 'test_data_array.yaml'
  end


  let :data_array_db do
    Keepassx.new data_array
  end


  let :test_db do
    @test_db
  end


  let :new_db do
    @new_db
  end


  let :test_group do
    Keepassx::Group.new :title => 'test_group', :id => 0, :icon => 20
  end

end
