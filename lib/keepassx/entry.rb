# One entry: [FIELDTYPE(FT)][FIELDSIZE(FS)][FIELDDATA(FD)]
#            [FT+FS+(FD)][FT+FS+(FD)][FT+FS+(FD)][FT+FS+(FD)][FT+FS+(FD)]...

# [ 2 bytes] FIELDTYPE
# [ 4 bytes] FIELDSIZE, size of FIELDDATA in bytes
# [ n bytes] FIELDDATA, n = FIELDSIZE

# Notes:
# - Strings are stored in UTF-8 encoded form and are null-terminated.
# - FIELDTYPE can be one of the following identifiers:
#   * 0000: Invalid or comment block, block is ignored
#   * 0001: UUID, uniquely identifying an entry, FIELDSIZE must be 16
#   * 0002: Group ID, identifying the group of the entry, FIELDSIZE = 4
#           It can be any 32-bit value except 0 and 0xFFFFFFFF
#   * 0003: Image ID, identifying the image/icon of the entry, FIELDSIZE = 4
#   * 0004: Title of the entry, FIELDDATA is an UTF-8 encoded string
#   * 0005: URL string, FIELDDATA is an UTF-8 encoded string
#   * 0006: UserName string, FIELDDATA is an UTF-8 encoded string
#   * 0007: Password string, FIELDDATA is an UTF-8 encoded string
#   * 0008: Notes string, FIELDDATA is an UTF-8 encoded string
#   * 0009: Creation time, FIELDSIZE = 5, FIELDDATA = packed date/time
#   * 000A: Last modification time, FIELDSIZE = 5, FIELDDATA = packed date/time
#   * 000B: Last access time, FIELDSIZE = 5, FIELDDATA = packed date/time
#   * 000C: Expiration time, FIELDSIZE = 5, FIELDDATA = packed date/time
#   * 000D: Binary description UTF-8 encoded string
#   * 000E: Binary data
#   * FFFF: Entry terminator, FIELDSIZE must be 0
#   '''

module Keepassx

  class Entry

    include Item

    FIELD_CLASS   = Keepassx::EntryField
    FIELD_MAPPING = {
        :title       => :title,
        :icon        => :imageid,
        :lastmod     => :last_mod_time,
        :lastaccess  => :last_acc_time,
        :creation    => :creation_time,
        :expire      => :expiration_time,
        :password    => :password,
        :username    => :username,
        :uuid        => :uuid,
        :url         => :url,
        :binary_desc => :binary_desc,
        :binary_data => :binary_data,
        :comment     => :notes,
    }


    # Create entries from raw data.
    #
    # @param header [Keepassx::Header] Keepassx database header.
    # @param groups [Array<Keepassx::Group>] Group list, the entry will bind to.
    # @param payload [StringIO] Raw data.
    # @return [Array<Keepassx::Entry>]
    def self.extract_from_payload(header, groups, payload)
      items = []
      header.entry_number.times do
        entry       = Entry.new(payload)
        entry.group = groups.detect { |g| g.id.eql? entry.group_id }
        items << entry
      end
      items
    end


    # Get list of supported entry fields.
    #
    # @return [Array<Symbol>]
    def self.fields
      FIELD_MAPPING.keys
    end


    def initialize(payload)
      super

      if payload.is_a? StringIO
        decode payload

      elsif payload.is_a? Hash
        fail "'title' is required" if payload[:title].nil?
        fail "'group' is required" if payload[:group].nil?
        self.group = payload[:group]

        field_list = FIELD_MAPPING.keys
        data = payload.select { |k| field_list.include? k }
        data[:group_id] = group.id

        @fields = []
        default_fields.merge(data).each do |k, v|
          fail "Unknown field: '#{k}'" unless self.respond_to? "#{k}=", true
          @fields << self.send("#{k}=", v)
        end

      else
        fail "Expecting StringIO or Hash, got #{payload.class}"
      end
    end


    attr_reader :group


    # Set parent group.
    #
    # @param v [Keepassx::Group] Parent group.
    # @return [Keepassx::Group]
    def group= v
      if v.is_a? Keepassx::Group
        self.group_id = v.id
        @group        = v
      else
        fail "Expected Keepassx::Group, got #{v.class}"
      end
    end


    def group_id
      get :groupid
    end


    FIELD_MAPPING.each do |method, field|
      define_method method do
        get field
      end

      define_method "#{method}=" do |v|
        set field, v
      end
    end


    private

    def default_fields
      @default_fields ||= {
          :uuid        => SecureRandom.uuid,
          :group_id    => nil,
          :icon        => 1,
          :title       => nil,
          :url         => nil,
          :username    => nil,
          :password    => nil,
          :comment     => nil,
          :creation    => Time.now,
          :lastmod     => Time.now,
          :lastaccess  => Time.now,
          :expire      => Time.local(2999, 12, 28, 23, 59, 59),
          :binary_desc => nil,
          :binary_data => nil,
          :terminator  => nil
      }
    end


    # Keep this method private in order to avoid group/group_id divergence
    def group_id= v
      set :groupid, v
    end

  end
end
