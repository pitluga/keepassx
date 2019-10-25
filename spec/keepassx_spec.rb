require 'spec_helper'

RSpec.describe Keepassx do

  describe '.new' do
    it 'should allow creation of database from scratch' do
      expect { |b| described_class.new('/tmp/test_db.kdb', &b) }.to yield_control
    end
  end

  describe '.open' do
    it 'should allow creation of database from scratch' do
      expect { |b| described_class.open('/tmp/test_db.kdb', &b) }.to yield_control
    end
  end

end
