require 'spec_helper'

describe Keepassx::Entry do

  include_context :keepassx

  let :entry_schema do
    Respect::HashSchema.define do |s|
      s.string :title
      s.integer :icon
      s.integer :lastmod
      s.integer :lastaccess
      s.integer :creation
      s.integer :expire
      s.string :password
      s.string :username
      s.string :uuid #, :format => :uuid FIXME: Implement uuid validator
      s.string :url, :format => :uri
      # s.string 'binary_desc' # 'binary_desc' comes empty in test data
      # s.string 'binary_data' # 'binary_data' comes empty in test data
      s.string :comment
    end
  end


  let :test_date do
    1410124392
  end


  let :test_entry do
    Keepassx::Entry.new :title => 'test_entry', :icon => 20,
        :username => 'test', :password => 'test', :url => 'https://example.com',
        :group => test_group, :creation => test_date,
        :comment => 'Test comment'
  end


  describe '#new' do

    it 'raise error when group is missing' do
      expect { Keepassx::Entry.new :title => 'test_entry',
          :icon => 20 }.to raise_error
    end


    it 'does not raise errors' do
      expect {test_entry}.to_not raise_error
    end
  end


  describe '#fields' do
    it 'returns the list of fields' do
      expect(Keepassx::Entry.fields.length).to eq 13 #  FIXME: Define 'let' constant
    end
  end


  describe '#to_hash' do

    it 'returns Hash entry representation' do
      expect(entry_schema.validate? test_entry.to_hash).to be true
    end  unless RUBY_VERSION =~ /1.8/ # Respect does not support ruby 1.8.x

    it 'set timestamps properly' do
      expect(test_entry.to_hash[:creation]).to eq test_date
    end

  end

end
