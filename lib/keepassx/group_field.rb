module Keepassx
  class GroupField
    FIELD_TYPES = [
      [0x0, 'ignored', :null],
      [0x1, 'group_id', :int],
      [0x2, 'name', :string],
      [0x3, 'creation_time', :date],
      [0x4, 'lastmod_time', :date],
      [0x5, 'lastacc_time', :date],
      [0x6, 'expire_time', :date],
      [0x7, 'imageid', :int],
      [0x8, 'level', :short],
      [0x9, 'flags', :int],
      [0xFFFF, 'terminator', :null]
    ]
    FIELD_TERMINATOR = 0xFFFF
    TYPE_CODE_FIELD_SIZE = 2   # unsigned short integer
    DATA_LENGTH_FIELD_SIZE = 4 # unsigned integer


    attr_reader :name, :data_type, :data

    def initialize(payload)
      type_code, @data_length = payload.read(TYPE_CODE_FIELD_SIZE + DATA_LENGTH_FIELD_SIZE).unpack('SI')
      @name, @data_type = _parse_type_code(type_code)
      @data = payload.read(@data_length).dup.force_encoding('UTF-8')
    end

    def terminator?
      name == 'terminator'
    end

    def length
      TYPE_CODE_FIELD_SIZE + DATA_LENGTH_FIELD_SIZE + @data_length
    end

    def _parse_type_code(type_code)
      (_, name, data_type) = FIELD_TYPES.detect do |(code, *rest)|
        code == type_code
      end
      [name, data_type]
    end
  end
end
