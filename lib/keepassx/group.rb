# One group: [FIELDTYPE(FT)][FIELDSIZE(FS)][FIELDDATA(FD)]
#            [FT+FS+(FD)][FT+FS+(FD)][FT+FS+(FD)][FT+FS+(FD)][FT+FS+(FD)]...
#
# [ 2 bytes] FIELDTYPE
# [ 4 bytes] FIELDSIZE, size of FIELDDATA in bytes
# [ n bytes] FIELDDATA, n = FIELDSIZE
#
# Notes:
# - Strings are stored in UTF-8 encoded form and are null-terminated.
# - FIELDTYPE can be one of the following identifiers:
#   * 0000: Invalid or comment block, block is ignored
#   * 0001: Group ID, FIELDSIZE must be 4 bytes
#           It can be any 32-bit value except 0 and 0xFFFFFFFF
#   * 0002: Group name, FIELDDATA is an UTF-8 encoded string
#   * 0003: Creation time, FIELDSIZE = 5, FIELDDATA = packed date/time
#   * 0004: Last modification time, FIELDSIZE = 5, FIELDDATA = packed date/time
#   * 0005: Last access time, FIELDSIZE = 5, FIELDDATA = packed date/time
#   * 0006: Expiration time, FIELDSIZE = 5, FIELDDATA = packed date/time
#   * 0007: Image ID, FIELDSIZE must be 4 bytes
#   * 0008: Level, FIELDSIZE = 2
#   * 0009: Flags, 32-bit value, FIELDSIZE = 4
#   * FFFF: Group entry terminator, FIELDSIZE must be 0
module Keepassx

  class Group

    include Item

    FIELD_CLASS   = Keepassx::GroupField
    FIELD_MAPPING = {
        :id         => :groupid,
        :title      => :group_name,
        :icon       => :imageid,
        :lastmod    => :lastmod_time,
        :lastaccess => :lastacc_time,
        :creation   => :creation_time,
        :expire     => :expire_time,
        :level      => :level,
        :flags      => :flags
    }


    def self.extract_from_payload(header, payload_io)
      groups = []
      header.group_number.times { groups << Group.new(payload_io) }
      groups
    end

    # return
    def self.fields
      FIELD_MAPPING.keys
    end


    attr_reader :parent


    def initialize payload
      super

      if payload.is_a? StringIO
        decode payload

      elsif payload.is_a? Hash
        fail "'title' is required" if payload[:title].nil?
        fail "'id' is required" if payload[:id].nil?

        group_parent = payload.delete :parent
        @fields      = []
        default_fields.merge(payload).each do |k, v|
          @fields << self.send("#{k.to_s}=", v)
        end

        self.parent = group_parent

      else
        fail "Expected StringIO or Hash, got #{payload.class}"
      end
    end


    FIELD_MAPPING.each do |method, field|
      define_method method do
        get field
      end

      define_method "#{method}=" do |v|
        set field, v
      end
    end


    def parent= v
      if v.is_a? Keepassx::Group
        self.level = v.level + 1 # FIXME: If parent is nil, then set level to 0
        @parent    = v

      elsif v.nil?
        self.level = 0 # Assume group located on top level if has no parent

      else
        fail "Expected Keepassx::Group, got #{v.class}"
      end
    end


    def level
      value = get :level
      value.nil? ? 0 : value
    end


    private

    def level= v
      set :level, v
    end


    def default_fields
      @default_field ||= {
          :id         => :unknown,
          :title      => :unknown,
          :icon       => 1,
          # Group's timestamps does not make sense to me,
          # hence removing that from defaults
          # :creation   => Time.now,
          # :lastmod    => Time.now,
          # :lastaccess => Time.now,
          # :expire     => Time.local(2999, 12, 28, 23, 59, 59),
          :level      => 0,
          :flags      => 0,
          :terminator => nil
      }
    end

  end
end
