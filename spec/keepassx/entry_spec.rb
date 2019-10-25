require 'spec_helper'

RSpec.describe Keepassx::Entry do

  let :entry_schema do
    Respect::HashSchema.define do |s|
      s.uuid     :id
      s.integer  :group_id
      s.integer  :icon
      s.string   :name
      s.string   :url, format: :uri
      s.string   :username
      s.string   :password
      s.string   :notes
      s.datetime :creation_time
      s.datetime :last_mod_time
      s.datetime :last_acc_time
      s.datetime :expiration_time
      # s.string  :binary_desc # 'binary_desc' comes empty in test data
      # s.string  :binary_data # 'binary_data' comes empty in test data
    end
  end

  let(:test_entry) { build(:entry) }


  describe '.fields' do
    it 'returns the list of fields' do
      expect(described_class.fields).to eq %w(ignored id group_id icon name url username password notes creation_time last_mod_time last_acc_time expiration_time binary_desc binary_data terminator)
    end
  end


  describe '.new' do
    it 'raise error when first argument is not a hash or a binary payload' do
      expect { Keepassx::Entry.new('foo') }.to raise_error(ArgumentError)
    end

    it 'raise error when name is not a string or is missing' do
      [0, :foo, [], {}, nil, ''].each do |name|
        expect { Keepassx::Entry.new(name: name, group_id: 0, icon: 20) }.to raise_error(ArgumentError)
      end
    end

    it 'raise error when group_id is not an integer or is missing' do
      ['foo', :foo, [], {}, nil, ''].each do |group_id|
        expect { Keepassx::Entry.new(name: 'test_entry', group_id: group_id, icon: 20) }.to raise_error(ArgumentError)
      end
    end

    it 'does not raise errors with valid data' do
      expect { test_entry }.to_not raise_error
    end
  end


  describe '#fields' do
    it 'returns the list of fields' do
      expect(test_entry.fields.length).to eq 15
    end
  end


  describe '#length' do
    it 'returns the length of fields' do
      expect(test_entry.length).to eq 189
    end
  end


  describe '#encode' do
    it 'returns the encoded version of fields' do
      expect { test_entry.encode }.to_not raise_error
    end
  end


  describe '#to_hash' do
    it 'returns Hash entry representation' do
      expect(entry_schema.validate?(test_entry.to_hash)).to be true
    end

    it 'returns Hash entry representation' do
      expect(entry_schema.validate?(build(:entry, id: '1').to_hash)).to be false
    end
  end


  describe 'fields are editable' do
    it 'should allow update of attributes' do
      test_entry.name = 'foo'
      expect(test_entry.name).to eq 'foo'
    end
  end
end
