# One entry: [FIELDTYPE(FT)][FIELDSIZE(FS)][FIELDDATA(FD)]
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

module Keepassx
  class Entry < Fieldable

    set_field_descriptor Keepassx::Field::Entry

    attr_reader :group

    def initialize(payload)
      super do
        # Do some validation
        raise ArgumentError, "'name' is required (type: string)" unless valid_string?(payload[:name])
        raise ArgumentError, "'group_id' is required (type: integer)" unless payload[:group] || valid_integer?(payload[:group_id])

        # First set @group and @group_id.
        # Remove key from payload to not interfere with KeePassX fields format
        self.group = payload.delete(:group)

        # Add group_id key to respect KeePassX fields format
        payload[:group_id] = group.id

        # Build list of fields
        @fields = build_payload(payload)
      end
    end


    class << self

      def extract_from_payload(header, payload)
        entries = []
        header.entries_count.times { entries << Entry.new(payload) }
        entries
      end

    end


    def group=(value)
      raise ArgumentError, "Expected Keepassx::Group, got #{value.class}" unless value.is_a?(Keepassx::Group)
      self.group_id = value.id
      @group        = value
      value
    end


    private


      def default_fields
        @default_fields ||= {
          id:              SecureRandom.uuid.gsub('-', ''),
          group_id:        nil,
          icon:            1,
          name:            nil,
          url:             nil,
          username:        nil,
          password:        nil,
          notes:           nil,
          creation_time:   Time.now,
          last_mod_time:   Time.now,
          last_acc_time:   Time.now,
          expiration_time: Time.local(2999, 12, 28, 23, 59, 59),
          binary_desc:     nil,
          binary_data:     nil,
          terminator:      nil
        }
      end


      # Keep this method private in order to avoid group/group_id divergence
      def group_id=(v)
        set :group_id, v
      end


      def exclusion_list
        super.concat(%w(binary_desc binary_data))
      end

  end
end
