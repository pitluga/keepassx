require 'spec_helper'

describe Keepassx::Database do
  describe 'self.open' do
    it "creates a new instance of the databse with the file" do
      db = Keepassx::Database.open(TEST_DATABASE_PATH)
      expect(db).to_not be nil
    end
  end

  describe "unlock" do
    before :each do
      @db = Keepassx::Database.open(TEST_DATABASE_PATH)
      expect(@db).to_not be nil
    end

    it "returns true when the master password is correct" do
      expect(@db.unlock('testmasterpassword')).to be true
    end

    it "returns false when the master password is incorrect" do
      expect(@db.unlock('bad password')).to be false
    end
  end

  describe "an unlocked database" do
    before :each do
      @db = Keepassx::Database.open(TEST_DATABASE_PATH)
      @db.unlock('testmasterpassword')
    end

    it "can find entries by their title" do
      expect(@db.entry("test entry").password).to eq "testpassword"
    end

    it "can find groups" do
      expect(@db.groups.map(&:name).sort).to eq ["Backup", "Internet", "eMail"]
    end

    it "can search for entries" do
      entries = @db.search "test"
      expect(entries.first.title).to eq "test entry"
    end

    it "can search for entries case-insensitively" do
      entries = @db.search "TEST"
      expect(entries.first.title).to eq "test entry"
    end

    it "will find the current values of entries with history" do
      entries = @db.search "entry2"
      expect(entries.size).to be 1
      expect(entries.first.title).to eq "entry2"
    end
  end
end
