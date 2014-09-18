require 'base64'
require 'stringio'
require 'openssl'
require 'digest/sha2'
require 'securerandom'
require 'rexml/document'

# Add backward compatibility stuff
if RUBY_VERSION =~ /1\.8/
  require 'backports/tools'
  require 'backports/1.9.1/symbol/empty'
  require 'backports/1.9.3/io/write'
  require 'time' # Get Time.parse

  unless SecureRandom.method_defined? :uuid
    module SecureRandom
      # Based on this post https://www.ruby-forum.com/topic/3171049#1035902
      def self.uuid
        s = hex 16
        [s[0..7], s[8..11], s[12..15], s[16..19], s[20..-1]].join '-'
      end
    end
  end
end


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
