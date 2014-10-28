module Keepassx

  module Field

    # FIELD_TERMINATOR = 0xFFFF # FIXME: Use it or remove it
    TYPE_CODE_FIELD_SIZE = 2 # unsigned short integer
    DATA_LENGTH_FIELD_SIZE = 4 # unsigned integer


    def initialize(payload)

      if payload.is_a? StringIO

        @type_code, data_length = payload.read(
            TYPE_CODE_FIELD_SIZE + DATA_LENGTH_FIELD_SIZE).unpack('SI')
        @name, @data_type = parse_type_code
        fail "Failed to determine field name from '#{payload.inspect}'" if
            @name.nil?
        fail "Failed to determine field typefrom '#{payload.inspect}'" if
            @data_type.nil?
        # Not using setter because it should be raw data here
        @data = payload.read(data_length) unless terminator?
        set_export_import_methods

      elsif payload.is_a? Hash
        @name = payload[:name].to_s
        type_set = self.class::FIELD_TYPES.detect do |_, name, _|
          name.eql? @name.to_s
        end
        @type_code, _, @data_type = type_set

        set_export_import_methods
        self.data = payload[:data]
      end

    rescue NoMethodError => e
      raise Keepassx::MalformedDataError.
          new "Read error at #{payload.lineno}" if e.name.eql? :unpack
      # fail
    end


    def encode
      buffer = [@type_code, size].pack 'SI'
      buffer << @data unless @data.nil? # Writing raw data
      # [buffer].pack "a#{size}"
      buffer
    end


    def terminator?
      @name.eql? 'terminator'
    end


    # Get raw data length
    #
    # @return [Integer]
    def length
      TYPE_CODE_FIELD_SIZE + DATA_LENGTH_FIELD_SIZE + size
    end


    def size
      case @data_type
        when :null
          0
        when :int
          4
        when :date
          5
        when :uuid
          16
        else
          (@data.nil?) && 0 || @data.length
      end
    end


    def data
        self.send @export_method
    end


    def data= value
        self.send @import_method, value
    end


    def raw
      @data
    end


    private

    def set_export_import_methods
      @export_method = "#{@data_type}".to_sym
      @import_method = "#{@data_type}=".to_sym
    end


    def parse_type_code
      (_, name, data_type) = self.class::FIELD_TYPES.detect do |(code, *rest)|
        code == @type_code
      end
      [name, data_type]
    end


    def string
      @data.chomp("\000")
    end


    def int
      @data.unpack('I')[0]
    end


    def short
      @data.unpack('S')[0]
    end


    def ascii
      # TODO: Add spec
      @data.unpack('H*')[0]
    end


    def date
      buffer = @data.unpack('C5')
      year = (buffer[0] << 6) | (buffer[1] >> 2)
      month = ((buffer[1] & 0b11) << 2) | (buffer[2] >> 6)
      day = ((buffer[2] & 0b111111) >> 1)
      hour = ((buffer[2] & 0b1) << 4) | (buffer[3] >> 4)
      min = ((buffer[3] & 0b1111) << 2) | (buffer[4] >> 6)
      sec = ((buffer[4] & 0b111111))

      Time.local(year, month, day, hour, min, sec)
    end


    def null
      nil
    end


    def shunt
      @data
    end


    def string= value
      @data = "#{value}\000"
      # @data.force_encoding 'ASCII-8BIT' if @data.respond_to? :force_encoding
    end


    def int= value
      @data = [value].pack('I')
    end


    def short= value
      @data = [value].pack('S')
    end


    def ascii= value
      @data = [value].pack('H*')
    end


    def date= value
      fail "Expected: Time, String or Fixnum, got: '#{value.class}'." unless
          [Time, String, Fixnum].include? value.class

      value = Time.parse value if value.is_a? String
      value = Time.at value if value.is_a? Fixnum

      sec, min, hour, day, month, year = value.to_a
      @data = [
          0x0000FFFF & ((year >> 6) & 0x0000003F),
          0x0000FFFF & (((year & 0x0000003f) << 2) |
              ((month >> 2) & 0x00000003)),
          0x0000FFFF & (((month & 0x00000003) << 6) |
              ((day & 0x0000001F) << 1) | ((hour >> 4) & 0x00000001)),
          0x0000FFFF & (((hour & 0x0000000F) << 4) |
              ((min >> 2) & 0x0000000F)),
          0x0000FFFF & (((min & 0x00000003) << 6) | (sec & 0x0000003F))
      ].pack('<C5')
    end


    def null= _
      @data = nil
    end


    def shunt= value
      @data = value
    end

  end
end
