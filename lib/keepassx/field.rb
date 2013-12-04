module Keepassx
  class Field
    FIELD_TERMINATOR = 0xFFFF
    TYPE_CODE_FIELD_SIZE = 2   # unsigned short integer
    DATA_LENGTH_FIELD_SIZE = 4 # unsigned integer

    attr_reader :name, :data_type, :data

    def initialize(payload, field_types)
      @field_types = field_types
      type_code, @data_length = payload.read(TYPE_CODE_FIELD_SIZE + DATA_LENGTH_FIELD_SIZE).unpack('SI')
      @name, @data_type = parse_type_code(type_code)
      @data = payload.read(@data_length).dup.force_encoding('UTF-8')
    end

    def terminator?
      name == 'terminator'
    end

    def length
      TYPE_CODE_FIELD_SIZE + DATA_LENGTH_FIELD_SIZE + @data_length
    end

    private

    def parse_type_code(type_code)
      (_, name, data_type) = @field_types.detect do |(code, *rest)|
        code == type_code
      end
      [name, data_type]
    end
  end
end
