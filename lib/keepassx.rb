require 'base64'
require 'stringio'
require 'openssl'
require 'digest/sha2'
require 'securerandom'
require 'rexml/document'

require 'keepassx/exceptions'
require 'keepassx/header'
require 'keepassx/utilities'
require 'keepassx/database'
require 'keepassx/field'
require 'keepassx/entry_field'
require 'keepassx/group_field'
require 'keepassx/item'
require 'keepassx/entry'
require 'keepassx/group'
require 'keepassx/aes_crypt'

module Keepassx

  class << self


    # Create Keepassx database
    #
    # @param opts [Hash] Keepassx database options.
    # @yield [opts]
    # @yieldreturn [Fixnum]
    # @return [Keepassx::Database]
    def new opts
      db = Database.new opts
      return db unless block_given?
      yield db
    end


    # Read Keepassx database from file storage.
    #
    # @param opts [Hash] Keepassx database options.
    # @yield [opts]
    # @yieldreturn [Fixnum]
    # @return [Keepassx::Database]
    def open opts
      db = Database.open opts
      return db unless block_given?
      yield db
    end
  end

end
