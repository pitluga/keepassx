require 'spec_helper'

describe Keepassx::Group do

  include_context :keepassx

  let :group_schema do
    Respect::HashSchema.define do |s|
      s.integer :id
      s.string :title
      s.integer :icon
      # s.datetime :lastmod
      # s.datetime :lastaccess
      # s.datetime :creation
      # s.datetime :expire
      s.integer :level
      s.integer :flags
    end
  end


  describe '#new' do
    it 'raise error when id is missing' do
      expect { Keepassx::Group.new :title => 'test_group', :icon => 20 }.
          to raise_error
    end

    it 'does not raise errors' do
      expect { test_group }.to_not raise_error
    end
  end


  describe '#fields' do
    it 'returns the list of fields' do
      expect(Keepassx::Group.fields.length).to eq 9
    end
  end


  describe '#to_hash' do
    it 'returns Hash group representation' do
      expect(group_schema.validate? test_group.to_hash).to be true
    end
  end unless RUBY_VERSION =~ /1.8/ # Respect does not support ruby 1.8.x

end
