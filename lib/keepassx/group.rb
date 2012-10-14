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
    def self.extract_from_payload(header, payload_io)
      groups = []
      header.ngroups.times do
        group = Group.new(payload_io)
        groups << group
      end
      groups
    end

    def initialize(payload_io)
      fields = []
      begin
        field = GroupField.new(payload_io)
        fields << field
      end while not field.terminator?

      @fields = fields
    end

    def length
      @fields.map(&:length).reduce(&:+)
    end

    def group_id
      @fields.detect { |field| field.name == 'groupid' }.data
    end

    def name
      @fields.detect { |field| field.name == 'group_name' }.data.chomp("\000")
    end
  end
end
