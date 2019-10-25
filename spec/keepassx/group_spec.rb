require 'spec_helper'

RSpec.describe Keepassx::Group do

  let :group_schema do
    Respect::HashSchema.define do |s|
      s.integer  :id
      s.string   :name
      s.integer  :icon
      s.datetime :creation_time
      s.datetime :last_mod_time
      s.datetime :last_acc_time
      s.datetime :expiration_time
      s.integer  :level
      s.integer  :flags
    end
  end

  let(:test_group) { build(:group) }


  describe '.fields' do
    it 'returns the list of fields' do
      expect(described_class.fields).to eq %w(ignored id name creation_time last_mod_time last_acc_time expiration_time icon level flags terminator)
    end
  end


  describe '.new' do
    it 'raise error when first argument is not a hash or a binary payload' do
      expect { Keepassx::Group.new('foo') }.to raise_error(ArgumentError)
    end

    it 'raise error when id is not an integer or is missing' do
      ['foo', :foo, [], {}, nil, ''].each do |id|
        expect { Keepassx::Group.new(id: id, name: 'test_group', icon: 20) }.to raise_error(ArgumentError)
      end
    end

    it 'raise error when name is not a string or is missing' do
      [0, :foo, [], {}, nil, ''].each do |name|
        expect { Keepassx::Group.new(id: 0, name: name, icon: 20) }.to raise_error(ArgumentError)
      end
    end

    it 'does not raise errors with valid data' do
      expect { test_group }.to_not raise_error
    end
  end


  describe '#fields' do
    it 'returns the list of fields' do
      expect(test_group.fields.length).to eq 10
    end
  end


  describe '#length' do
    it 'returns the length of fields' do
      expect(test_group.length).to eq 105
    end
  end


  describe '#encode' do
    it 'returns the encoded version of fields' do
      expect { test_group.encode }.to_not raise_error
    end
  end


  describe '#to_hash' do
    it 'returns Hash group representation' do
      expect(group_schema.validate?(test_group.to_hash)).to be true
    end
  end


  describe '#entries' do
    it 'returns the list of entries' do
      expect(test_group.entries.length).to eq 0
    end
  end

  describe 'fields are editable' do
    it 'should allow update of attributes' do
      test_group.name = 'foo'
      expect(test_group.name).to eq 'foo'
    end
  end
end
