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

    attr_reader :fields

    def self.extract_from_payload(header, payload_io)
      groups = []
      header.nentries.times do
        group = Entry.new(payload_io)
        groups << group
      end
      groups
    end

    attr_reader :fields

    def initialize(payload_io)
      fields = []
      begin
        field = EntryField.new(payload_io)
        fields << field
      end while not field.terminator?

      @fields = fields
    end

    def length
      @fields.map(&:length).reduce(&:+)
    end

    def method_missing(name)
      @fields.detect { |field| field.name == name.to_s }.data.chomp("\000")
    end

    def inspect
      "Entry<title=#{title.inspect}, username=[FILTERED], password=[FILTERED], notes=#{notes.inspect}>"
    end
  end
end
