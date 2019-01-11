# frozen_string_literal: true

require 'base64'
require 'stringio'
require 'openssl'
require 'securerandom'
require 'digest/sha2'
require 'yaml'

require 'keepassx/database/dumper'
require 'keepassx/database/loader'
require 'keepassx/database/finder'
require 'keepassx/database'
require 'keepassx/field/base'
require 'keepassx/field/entry'
require 'keepassx/field/group'
require 'keepassx/fieldable'
require 'keepassx/entry'
require 'keepassx/group'
require 'keepassx/header'
require 'keepassx/aes_crypt'

module Keepassx
  class << self

    # Create Keepassx database
    #
    # @param opts [Hash] Keepassx database options.
    # @yield [opts]
    # @yieldreturn [Fixnum]
    # @return [Keepassx::Database]
    def new(opts)
      db = Database.new(opts)
      yield db if block_given?
      db
    end


    # Read Keepassx database from file storage.
    #
    # @param opts [Hash] Keepassx database options.
    # @yield [opts]
    # @yieldreturn [Fixnum]
    # @return [Keepassx::Database]
    def open(opts)
      db = Database.new(opts)
      yield db if block_given?
      db
    end

  end
end
