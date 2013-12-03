module Keepassx
  class EntryField
     FIELD_TYPES = [
       [0x0, 'ignored', :null],
       [0x1, 'uuid', :ascii],
       [0x2, 'group_id', :int],
       [0x3, 'image_id', :int],
       [0x4, 'title', :string],
       [0x5, 'url', :string],
       [0x6, 'username', :string],
       [0x7, 'password', :string],
       [0x8, 'notes', :string],
       [0x9, 'creation_time', :date],
       [0xa, 'last_mod_time', :date],
       [0xb, 'last_acc_time', :date],
       [0xc, 'expiration_time', :date],
       [0xd, 'binary_desc', :string],
       [0xe, 'binary_data', :shunt],
       [0xFFFF, 'terminator', :nil]
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
