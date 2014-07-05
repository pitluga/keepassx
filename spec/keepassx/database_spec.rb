require 'spec_helper'
# require 'ruby-prof'
## FIXME: Add exception tests.
describe Keepassx::Database do

  include_context :keepassx

  describe '#open' do
    it 'creates a new instance of the databse with the file' do
      expect(test_db).to_not be nil
    end
  end


  describe '#new' do
    subject { Keepassx }
    let(:db1) { subject.new data_array }
    let(:db2) { subject.new data_array }
    it 'has the same checksum for the same data' do
      # warn "db1: #{File.write '/tmp/db1', db1.entries.inspect}>><<"
      # warn "db2: #{File.write '/tmp/db2', db2.entries.inspect}>><<"
      expect(db1.checksum).to eq db2.checksum
    end
  end


  describe '#unlock' do

    it 'returns false when the master password is incorrect' do
      expect(test_db.unlock('bad password')).to be false
    end


    it 'returns true when the master password is correct' do
      expect(test_db.unlock('testmasterpassword')).to be true
    end

  end


  describe '#locked?' do
    it 'returns false when unlocked' do
      expect(test_db.locked?).to be false
    end
  end


  context 'unlocked database' do

    it 'can find entries by their title' do
      # FIXME: Add more field tests
      expect(test_db.entry(:title => 'test entry').password).to eq 'testpassword'
      expect(test_db.entry(:title => 'test entry').creation).to eq Time.
          local 2011, 9, 3, 15, 34, 47
    end


    it 'can find groups' do
      expect(test_db.groups.map(&:title).sort).
          to eq ['Backup', 'Internet', 'Web', 'Wikipedia', 'eMail']
    end


    it 'has "Internet" group level properly set' do
      expect(test_db.group(:Internet).level).to eq 0
    end


    it 'has "Internet" group parent properly set' do
      expect(test_db.group(:Internet).parent).to be nil
    end


    it 'has "Web" group level properly set' do
      expect(test_db.group(:Web).level).to eq 1
    end


    it 'has "Web" group parent properly set' do
      expect(test_db.group(:Web).parent).to be test_db.group(:Internet)
    end


    it 'has "eMail" group level properly set' do
      expect(test_db.group(:eMail).level).to eq 0
    end


    it 'has "eMail" group parent properly set' do
      expect(test_db.group(:eMail).parent).to be nil
    end


    it 'can search for entries' do
      expect(test_db.search('test').first.title).to eq 'test entry'
    end


    it 'can search for entries case-insensitively' do
      expect(test_db.search('TEST').first.title).to eq 'test entry'
    end


    it 'will find the current values of entries with history' do
      entries = test_db.search 'entry2'
      expect(entries.size).to be 1
      expect(entries.first.title).to eq 'entry2'
    end


    it 'can add and delete groups and entries' do
      expect { @group = test_db.add :group, :title => 'group3' }.to_not raise_error

      expect { @entry = Keepassx::Entry.new(
          :title => 'entry3',
          :group => @group
      ) }.to_not raise_error

      expect { test_db.add(@entry) }.to_not raise_error
      expect(test_db.entry :title => 'entry3', :group => @group).to_not be nil

      expect { @entry = Keepassx::Entry.new(
          :title => 'entry4',
          :group => @group
      ) }.to_not raise_error
      expect { test_db.add(@entry) }.to_not raise_error
      expect(test_db.entry :title => 'entry4', :group => @group).to_not be nil

      expect(test_db.entries(:group => @group).length).to eq 2

      expect(test_db.delete(:group, :title => 'group3').class).to be Keepassx::Group
      expect(test_db.entries :group => @group).to eq []
    end


    it 'can be exported to XML' do
      expect { @xml = test_db.to_xml }.to_not raise_error
      expect(@xml.doctype.name).to eq 'KEEPASSX_DATABASE'
      expect(@xml.root.name).to eq 'database'
      # require 'rexml/formatters/pretty'
      # formatter = REXML::Formatters::Pretty.new 2
      # formatter.compact = true # This is the magic line that does what you need!
      # formatter.write @xml, $stderr
      # formatter.write @xml, File.new('/tmp/keepass.xml', 'w+')
      # warn @xml
    end

  end


  context 'new database' do

    it 'is properly initialized' do
      expect(new_db.valid?).to be true
    end


    # Unlocked by default for new container
    it 'is unlocked' do
      expect(new_db.locked?).to be false
    end


    it 'has non-empty checksum ' do
      expect(test_db.checksum).to_not be nil
      expect(test_db.checksum).to_not be ''
    end


    it 'can add groups and entries' do
      [
          { :title => :Internet, :icon => 1 },
          { :title => :eMail, :icon => 19 },
          {  :title => :Web, :parent => :Internet, :icon => 61 },
          { :title => :Wikipedia, :parent => :Web, :icon => 54 }
      ].each do |opts|
        expect { new_db.add(:group, opts) }.to_not raise_error
      end
    end


    it 'contains group "eMail" with proper index value' do
      expect(new_db.index new_db.group(:eMail)).to eq 3
    end


    it 'contains group "eMail" with proper level value' do
      expect(new_db.group(:eMail).level).to eq 0
    end


    it 'contains group "Web" with proper level value' do
      expect(new_db.index new_db.group(:Web)).to eq 1
    end


    it 'contains group "Web" with proper level value' do
      expect(new_db.group(:Web).level).to eq 1
    end


    it 'contains group "Wikipedia" with proper level value' do
      expect(new_db.index new_db.group(:Wikipedia)).to eq 2
    end

    it 'contains group "Wikipedia" with proper level value' do
      expect(new_db.group(:Wikipedia).level).to eq 2
    end


    it 'adds new entry "test entry"' do
      # FIXME: There's some value set for binary_data field
      expect { new_db.add(:entry,
          :title   => 'test entry', :username => 'testuser',
          :url     => 'http://example.com/testurl', :password => 'testpassword',
          :comment => 'test comment', :group => :Internet)
      }.to_not raise_error
    end


    it 'adds new entry "entry2"' do
      expect { new_db.add(:entry,
          :title    => 'entry2', :username => 'user', :url => 'http://example.com',
          :password => 'pass2', :comment => 'comment',
          :group    => :Internet)
      }.to_not raise_error
    end


    it 'adds new entry "test entry2"' do
      expect { new_db.add(:entry,
          :title   => 'test entry2', :username => 'testuser',
          :url     => 'http://example.com/testurl', :password => 'testpassword',
          :comment => 'test comment', :group => :Web)
      }.to_not raise_error
    end


    it 'does not change checksum after save' do
      @new_db_checksum = @new_db.checksum
      expect { new_db.save 'testmasterpassword' }.to_not raise_error
      expect(new_db.checksum).to eq @new_db_checksum
    end


    it 'saves checksum properly' do
      expect(new_db.header.contents_hash).to eq new_db.checksum
    end


    it 'can delete entry' do
      group = new_db.add(:group, :title => 'Test Group 1')
      new_db.add_entry(:title => 'Test Entry 1', :group => group)

      expect {new_db.delete group}.to_not raise_error
    end


    it 'matches reference database' do
      # expect(new_db = Keepassx::Database.open(NEW_DATABASE_PATH)).to_not be nil
      expect(new_db.header.group_number).to eq 4

      # FIXME: Delete functionality seems not to work properly, should be 3 here
      expect(new_db.header.entry_number).to eq 4 # TODO: Don't forget about meta  entries
      expect(new_db.unlock 'testmasterpassword').to be true

      # expect(new_db.index new_db.group(:Backup)).to eq 4
      # expect(new_db.group(:Backup).level).to eq 0

      new_db.groups.each do |group|
        expect(group.title).to eq test_db.group(:title => group.title).title
        expect(group.level).to eq test_db.group(group.title).level
      end

      # TODO: Implement entries verification using reference database
      # new_db.entries.each do |entry|
      #   expect(entry.username).to eq test_db.entry(:title => entry.title).username
      #   expect(entry.group.title).to eq test_db.entry(entry.title).
      #       group.title
      # end
      expect { new_db.save 'testmasterpassword' }.to_not raise_error

    end

  end

  context 'new database from array' do

    it 'properly initialized from Array' do
      expect { data_array_db }.to_not raise_error
    end


    it 'has grup_number counter properly set' do
      expect(data_array_db.header.group_number).to eq 5
    end


    it 'contains proper number of test groups' do
      expect(data_array_db.groups.length).to eq 5
    end


    it 'contains proper number of test entries' do
      expect(data_array_db.entries.length).to eq 4
    end


    it 'has entry counter properly set' do
      expect(data_array_db.header.entry_number).to eq 4
    end


    it 'preserves original Array' do
      expect(data_array).to eq original_data_array
    end

  end


  describe '#to_a' do

    let :database_schema do
      # FIXME: Figure out how to properly define schema for nested Array
      Respect::ArraySchema.define do |s|
        s.item do |i|
          # i.hash
        end
      end
    end

    it 'returns Array database representation' do
      # expect(database_schema.validate? data_array_db.to_a).to be true
      expect(data_array_db.to_a.class).to be Array
    end

  end

end
