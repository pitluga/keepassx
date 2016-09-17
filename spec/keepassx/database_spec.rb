require 'spec_helper'

describe Keepassx::Database do

  GROUPS_COUNT  = 5
  ENTRIES_COUNT = 5

  let(:data_array) { YAML.load(File.read(File.join(FIXTURE_PATH, 'test_data_array.yml'))) }
  let(:data_array_dumped) { File.read(File.join(FIXTURE_PATH, 'test_data_array_dumped.yml')) }

  let(:test_db) { Keepassx::Database.new(TEST_DATABASE_PATH) }
  let(:test_db_dumped) { File.read(File.join(FIXTURE_PATH, 'database_test_dumped.yml')) }

  let(:empty_db) { Keepassx::Database.new(EMPTY_DATABASE_PATH) }
  let(:test_group) { build(:group) }
  let(:test_entry) { build(:entry) }


  describe 'empty database' do
    before :each do
      empty_db.unlock('test')
    end

    it 'should have 2 groups' do
      expect(empty_db.groups.size).to eq 2
      expect(empty_db.groups.map(&:name).sort).to eq ['Internet', 'eMail']
    end

    it 'should have 2 special entries' do
      expect(empty_db.entries.size).to eq 2
      expect(empty_db.entries.map(&:name).sort).to eq ['Meta-Info', 'Meta-Info']
    end

    it 'should have 1 KPX_CUSTOM_ICONS_4 entry' do
      entry = empty_db.find_entry(notes: 'KPX_CUSTOM_ICONS_4')
      expect(entry).to be_a(Keepassx::Entry)
      expect(entry.notes).to eq 'KPX_CUSTOM_ICONS_4'
    end

    it 'should have 1 KPX_GROUP_TREE_STATE entry' do
      entry = empty_db.find_entry(notes: 'KPX_GROUP_TREE_STATE')
      expect(entry).to be_a(Keepassx::Entry)
      expect(entry.notes).to eq 'KPX_GROUP_TREE_STATE'
    end
  end


  describe '.new' do
    context 'when database is instanciated from file' do
      let(:test_db) { described_class.new(File.open(TEST_DATABASE_PATH)) }

      before :each do
        test_db.unlock('testmasterpassword')
      end

      it 'properly initialized from file' do
        expect { test_db }.to_not raise_error
      end

      it 'should have valid headers' do
        expect(test_db.valid?).to be true
      end

      it 'should have valid length' do
        expect(test_db.length).to eq 1457
      end

      it 'should have valid encryption_type headers' do
        expect(test_db.header.encryption_type).to eq 'SHA2'
      end

      it 'has groups_count counter properly set' do
        expect(test_db.header.groups_count).to eq GROUPS_COUNT
      end

      it 'has entries_count counter properly set' do
        expect(test_db.header.entries_count).to eq ENTRIES_COUNT
      end

      it 'contains proper number of test groups' do
        expect(test_db.groups.length).to eq GROUPS_COUNT
      end

      it 'contains proper number of test entries' do
        expect(test_db.entries.length).to eq ENTRIES_COUNT
      end

      it 'preserves original data' do
        expect(test_db.to_yaml(skip_date: true)).to eq test_db_dumped
      end
    end

    context 'when database is instanciated from string' do
      let(:test_db) { described_class.new(TEST_DATABASE_PATH) }

      before :each do
        test_db.unlock('testmasterpassword')
      end

      it 'properly initialized from string' do
        expect { test_db }.to_not raise_error
      end

      it 'should have valid headers' do
        expect(test_db.valid?).to be true
      end

      it 'should have valid length' do
        expect(test_db.length).to eq 1457
      end

      it 'should have valid encryption_type headers' do
        expect(test_db.header.encryption_type).to eq 'SHA2'
      end

      it 'has groups_count counter properly set' do
        expect(test_db.header.groups_count).to eq GROUPS_COUNT
      end

      it 'has entries_count counter properly set' do
        expect(test_db.header.entries_count).to eq ENTRIES_COUNT
      end

      it 'contains proper number of test groups' do
        expect(test_db.groups.length).to eq GROUPS_COUNT
      end

      it 'contains proper number of test entries' do
        expect(test_db.entries.length).to eq ENTRIES_COUNT
      end

      it 'preserves original data' do
        expect(test_db.to_yaml(skip_date: true)).to eq test_db_dumped
      end
    end

    context 'when database is instanciated from array' do
      let(:test_db) { described_class.new(data_array) }

      it 'properly initialized from Array' do
        expect { test_db }.to_not raise_error
      end

      it 'should have valid headers' do
        expect(test_db.valid?).to be true
      end

      it 'should have valid length' do
        expect(test_db.length).to eq 2189
      end

      it 'should have valid encryption_type headers' do
        expect(test_db.header.encryption_type).to eq 'SHA2'
      end

      it 'has groups_count counter properly set' do
        expect(test_db.header.groups_count).to eq 13
      end

      it 'has entries_count counter properly set' do
        expect(test_db.header.entries_count).to eq 4
      end

      it 'contains proper number of test groups' do
        expect(test_db.groups.length).to eq 13
      end

      it 'contains proper number of test entries' do
        expect(test_db.entries.length).to eq 4
      end

      it 'preserves original data' do
        expect(test_db.to_yaml(skip_date: true)).to eq data_array_dumped
      end
    end
  end


  describe '#unlock' do
    it 'returns true when the master password is correct' do
      expect(test_db.unlock('testmasterpassword')).to be true
    end

    it 'returns false when the master password is incorrect' do
      expect(test_db.unlock('bad password')).to be false
    end
  end


  describe '#locked?' do
    it 'returns true when database is locked' do
      expect(test_db.locked?).to be true
    end

    it 'returns false when database is unlocked' do
      test_db.unlock('testmasterpassword')
      expect(test_db.locked?).to be false
    end
  end


  describe '#to_a' do
    it 'returns Array database representation' do
      expect(described_class.new(data_array).to_a.class).to be Array
    end
  end


  describe '#checksum' do
    let(:db1) { described_class.new data_array }
    let(:db2) { described_class.new data_array }

    it 'has the same checksum for the same data' do
      expect(db1.checksum).to eq db2.checksum
    end
  end


  context 'unlocked database' do
    before :each do
      test_db.unlock('testmasterpassword')
    end

    describe '#entries' do
      it 'has entries' do
        expect(test_db.entries.map(&:name).sort).to eq ['Meta-Info', 'Meta-Info', 'entry2', 'test entry', 'test entry 2']
      end
    end

    describe '#groups' do
      it 'has groups' do
        expect(test_db.groups.map(&:name).sort).to eq ['Backup', 'Internet', 'Web', 'Wikipedia', 'eMail']
      end
    end

    describe '#find_entry' do
      it 'can find entries by their name' do
        expect(test_db.find_entry('test entry').password).to eq 'testpassword'
        expect(test_db.find_entry(name: 'test entry').creation_time).to eq Time.local(2011, 9, 3, 15, 34, 47)
        expect(test_db.find_entry('foo')).to be nil
      end
    end

    describe '#find_group' do
      it 'can find groups by their name' do
        expect(test_db.find_group('Backup').name).to eq 'Backup'
        expect(test_db.find_group('foo')).to be nil
      end

      it 'has "Internet" group level properly set' do
        expect(test_db.find_group('Internet').level).to eq 0
      end

      it 'has "Internet" group parent properly set' do
        expect(test_db.find_group('Internet').parent).to be nil
      end

      it 'has "Web" group level properly set' do
        expect(test_db.find_group('Web').level).to eq 1
      end

      it 'has "Web" group parent properly set' do
        expect(test_db.find_group('Web').parent).to eq test_db.find_group('Internet')
      end

      it 'has "Wikipedia" group level properly set' do
        expect(test_db.find_group('Wikipedia').level).to eq 2
      end

      it 'has "Wikipedia" group parent properly set' do
        expect(test_db.find_group('Wikipedia').parent).to eq test_db.find_group('Web')
      end

      it 'has "eMail" group level properly set' do
        expect(test_db.find_group('eMail').level).to eq 0
      end

      it 'has "eMail" group parent properly set' do
        expect(test_db.find_group('eMail').parent).to be nil
      end
    end

    describe '#find_entries' do
      it 'should returns a list of entries' do
        expect(test_db.find_entries).to eq test_db.entries
        expect { |b| test_db.find_entries(&b) }.to yield_successive_args(*test_db.entries)
      end
    end

    describe '#find_groups' do
      it 'should returns a list of groups' do
        expect(test_db.find_groups).to eq test_db.groups
        expect { |b| test_db.find_groups(&b) }.to yield_successive_args(*test_db.groups)
      end
    end

    describe '#search' do
      it 'can search for entries' do
        entries = test_db.search('test')
        expect(entries.first.name).to eq 'test entry'
      end

      it 'can search for entries case-insensitively' do
        entries = test_db.search('TEST')
        expect(entries.first.name).to eq 'test entry'
      end

      # it 'will find the current values of entries with history' do
      #   entries = test_db.search 'entry2'
      #   expect(entries.size).to eq 1
      #   expect(entries.first.name).to eq 'entry2'
      #   expect(entries.first.backup?).to be true
      # end
    end

    describe '#add_group' do
      context 'when arg is a Keepassx::Group' do
        it 'should increment groups_count' do
          expect(test_db.groups.size).to eq GROUPS_COUNT
          test_db.add_group(test_group)
          expect(test_db.groups.size).to eq GROUPS_COUNT + 1
          expect(test_db.header.groups_count).to eq GROUPS_COUNT + 1
        end
      end

      context 'when arg is a Hash of options' do
        it 'should increment groups_count' do
          expect(test_db.groups.size).to eq GROUPS_COUNT
          test_db.add_group(attributes_for(:group))
          expect(test_db.groups.size).to eq GROUPS_COUNT + 1
          expect(test_db.header.groups_count).to eq GROUPS_COUNT + 1
        end
      end

      context 'when arg is neither a Keepassx::Group or a Hash of options' do
        it 'should raise an error' do
          expect { test_db.add_group(nil) }.to raise_error(ArgumentError)
        end
      end

      context 'with nested groups' do
        it 'should increment groups_count' do
          expect(test_db.groups.size).to eq GROUPS_COUNT
          parent_group = test_db.add_group(attributes_for(:group, id: 0, name: 'parent_group'))
          expect(test_db.groups.size).to eq GROUPS_COUNT + 1
          expect(test_db.groups).to include(parent_group)
          child_group = test_db.add_group(attributes_for(:group, id: 1, name: 'child_group', parent: parent_group))
          expect(test_db.groups.size).to eq GROUPS_COUNT + 2
          expect(test_db.header.groups_count).to eq GROUPS_COUNT + 2
          expect(child_group.parent).to eq parent_group
        end

        it 'should increment groups_count' do
          expect(test_db.groups.size).to eq GROUPS_COUNT
          parent_group = test_db.add_group(attributes_for(:group, id: 0, name: 'parent_group'))
          expect(test_db.groups.size).to eq GROUPS_COUNT + 1
          expect(test_db.groups).to include(parent_group)
          child_group = test_db.add_group(attributes_for(:group, id: 1, name: 'child_group', parent: :parent_group))
          expect(test_db.groups.size).to eq GROUPS_COUNT + 2
          expect(test_db.header.groups_count).to eq GROUPS_COUNT + 2
          expect(child_group.parent).to eq parent_group
        end
      end
    end

    describe '#add_entry' do
      context 'when arg is a Keepassx::Entry' do
        it 'should increment entries_count' do
          expect(test_db.entries.size).to eq ENTRIES_COUNT
          test_db.add_entry(test_entry)
          expect(test_db.entries.size).to eq ENTRIES_COUNT + 1
          expect(test_db.header.entries_count).to eq ENTRIES_COUNT + 1
        end
      end

      context 'when arg is a Hash of options' do
        it 'should increment entries_count' do
          expect(test_db.entries.size).to eq ENTRIES_COUNT
          test_db.add_entry(attributes_for(:entry))
          expect(test_db.entries.size).to eq ENTRIES_COUNT + 1
          expect(test_db.header.entries_count).to eq ENTRIES_COUNT + 1
        end
      end

      context 'when arg is neither a Keepassx::Group or a Hash of options' do
        it 'should raise an error' do
          expect { test_db.add_group(nil) }.to raise_error(ArgumentError)
        end
      end
    end

    describe '#delete_group' do
      it 'should decrement entries_count' do
        group = test_db.find_group('eMail')
        expect(test_db.groups.size).to eq GROUPS_COUNT
        expect(test_db.header.groups_count).to eq GROUPS_COUNT
        test_db.delete_group(group)
        expect(test_db.groups.size).to eq GROUPS_COUNT - 1
        expect(test_db.header.groups_count).to eq GROUPS_COUNT - 1
      end
    end

    describe '#delete_entry' do
      it 'should decrement entries_count' do
        entry = test_db.find_entry('test entry')
        expect(test_db.entries.size).to eq ENTRIES_COUNT
        expect(test_db.header.entries_count).to eq ENTRIES_COUNT
        test_db.delete_entry(entry)
        expect(test_db.entries.size).to eq ENTRIES_COUNT - 1
        expect(test_db.header.entries_count).to eq ENTRIES_COUNT - 1
      end
    end

    describe '#save' do
      context 'when database is saved from an existing file' do
        it 'should save the database in KeePassX format' do
          # Save database in /tmp to not override existing one
          expect { test_db.save(path: '/tmp/keepass1.kdb') }.to_not raise_error
          expect(File.exist?('/tmp/keepass1.kdb')).to be true

          # Reopen it and compare with original db
          db = described_class.new('/tmp/keepass1.kdb')
          expect(db.locked?).to be true
          db.unlock('testmasterpassword')
          expect(db.to_yaml).to eq test_db.to_yaml

          # Be sure to delete existing tmp files
          expect(File.unlink('/tmp/keepass1.kdb')).to eq 1
          expect(File.exist?('/tmp/keepass1.kdb')).to be false
        end
      end

      context 'when database is saved from a data file' do
        it 'should raise an error if path is not set' do
          test_db = described_class.new(data_array)
          expect { test_db.save }.to raise_error(ArgumentError)
        end

        it 'should raise an error if path is not set' do
          test_db = described_class.new(data_array)
          expect { test_db.save(password: 'foo') }.to raise_error(ArgumentError)
        end

        it 'should raise an error if password is not set' do
          test_db = described_class.new(data_array)
          expect { test_db.save(path: '/tmp/keepass2.kdb') }.to raise_error(ArgumentError)
        end

        it 'should save the database if the path and the password are set' do
          # Create new db from array of data
          test_db = described_class.new(data_array)

          # Save database in /tmp
          expect { test_db.save(path: '/tmp/keepass2.kdb', password: 'testmasterpassword') }.to_not raise_error
          expect(File.exist?('/tmp/keepass2.kdb')).to be true

          # Reopen it and compare with original db
          db = described_class.new('/tmp/keepass2.kdb')
          expect(db.locked?).to be true
          db.unlock('testmasterpassword')
          expect(db.to_yaml).to eq test_db.to_yaml

          # Be sure to delete existing tmp files
          expect(File.unlink('/tmp/keepass2.kdb')).to eq 1
          expect(File.exist?('/tmp/keepass2.kdb')).to be false
        end
      end
    end
  end


  describe 'create database from scratch' do
    it 'should allow creation of database from scratch' do
      # Create a new Database object
      db = described_class.new('/tmp/test_db.kdb')
      # Add a group
      group = db.add_group(name: 'Foo')
      # Add an entry in this group
      entry = db.add_entry(name: 'Bar', group: group)
      # Save database
      expect { db.save(password: 'testpassword') }.to_not raise_error
      # Do some checks
      expect(File.exist?('/tmp/test_db.kdb')).to be true

      # Reopen it and compare with original db
      new_db = described_class.new('/tmp/test_db.kdb')
      expect(new_db.locked?).to be true
      new_db.unlock('testpassword')
      expect(new_db.to_yaml(skip_date: true)).to eq db.to_yaml(skip_date: true)

      # Be sure to delete existing tmp files
      expect(File.unlink('/tmp/test_db.kdb')).to eq 1
    end
  end
end
