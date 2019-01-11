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
  class Group < Fieldable

    set_field_descriptor Keepassx::Field::Group

    attr_accessor :entries
    attr_reader   :parent

    def initialize(payload)
      @parent  = nil
      @entries = []

      super do
        # Do some validation
        raise ArgumentError, "'id' is required (type: integer)" unless valid_integer?(payload[:id])
        raise ArgumentError, "'name' is required (type: string)" unless valid_string?(payload[:name])

        # First set @parent and @level.
        # Remove key from payload to not interfere with KeePassX fields format
        self.parent = payload.delete(:parent)

        # Build list of fields
        @fields = build_payload(payload)
      end
    end


    class << self

      def extract_from_payload(header, payload)
        groups = []
        header.groups_count.times { groups << Group.new(payload) }
        groups
      end

    end


    def parent=(value)
      raise ArgumentError, "Expected Keepassx::Group or nil, got #{value.class}" unless valid_parent?(value)

      if value.is_a?(Keepassx::Group)
        self.level = value.level + 1
        @parent    = value

      elsif value.nil?
        # Assume, group is located at the top level, in case it has no parent
        self.level = 0
        @parent    = nil
      end
    end


    # Redefine #level method to return 0 instead of nil
    def level
      value = get :level
      value.nil? ? 0 : value
    end


    def ==(other)
      return false if other.nil?

      parent == other.parent  &&
        name   == other.name  &&
        id     == other.id    &&
        level  == other.level &&
        icon   == other.icon
    end


    private


      # Redefine #level= to make it private :
      # Setting group level only is a non-sense as it depends
      # on parent group.
      def level=(value)
        set :level, value
      end


      def default_fields
        @default_fields ||= {
          id:              :unknown,
          name:            :unknown,
          creation_time:   Time.now,
          last_mod_time:   Time.now,
          last_acc_time:   Time.now,
          expiration_time: Time.local(2999, 12, 28, 23, 59, 59),
          icon:            1,
          level:           0,
          flags:           0,
          terminator:      nil,
        }
      end


      def valid_parent?(object)
        object.is_a?(Keepassx::Group) || object.nil?
      end

  end
end
