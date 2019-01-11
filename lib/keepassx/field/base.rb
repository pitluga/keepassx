# frozen_string_literal: true

module Keepassx
  module Field
    class Base

      FIELD_TERMINATOR       = 0xFFFF
      TYPE_CODE_FIELD_SIZE   = 2 # unsigned short integer
      DATA_LENGTH_FIELD_SIZE = 4 # unsigned integer

      attr_reader :name, :data_type, :type_code


      def initialize(payload)
        if payload.is_a?(StringIO)
          @type_code, data_length = payload.read(TYPE_CODE_FIELD_SIZE + DATA_LENGTH_FIELD_SIZE).unpack('SI')
          _, @name, @data_type = self.class.fields_description.find { |type_code, _, _| type_code == @type_code }

          # Not using setter because it should be raw data here
          @data = payload.read(data_length)

          # Set export_import_methods *after* setting data
          set_export_import_methods(@data_type)

        elsif payload.is_a?(Hash)
          @name = payload[:name].to_s
          @type_code, _, @data_type = self.class.fields_description.find { |_, name, _| name == @name }

          # Set export_import_methods *before* setting data
          set_export_import_methods(@data_type)

          # Using setter because we need to convert data here
          self.data = payload[:data]
        end
      end


      def data
        send(@export_method)
      end


      def data=(value)
        send(@import_method, value)
      end


      def terminator?
        name == 'terminator'
      end


      def length
        TYPE_CODE_FIELD_SIZE + DATA_LENGTH_FIELD_SIZE + size
      end


      def size
        case data_type
        when :null
          0
        when :int
          4
        when :date
          5
        when :uuid
          16
        else
          (@data.nil? && 0) || @data.length
        end
      end


      def encode
        buffer = [type_code, size].pack 'SI'
        buffer << @data unless @data.nil?
        buffer
      end


      private


        # rubocop:disable Style/UnneededInterpolation
        def set_export_import_methods(type)
          @export_method = "#{type}".to_sym
          @import_method = "#{type}=".to_sym
        end
        # rubocop:enable Style/UnneededInterpolation


        ### EXPORT METHODS

        def null
          nil
        end


        def shunt
          @data
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
          year   = (buffer[0] << 6) | (buffer[1] >> 2)
          month  = ((buffer[1] & 0b11) << 2) | (buffer[2] >> 6)
          day    = ((buffer[2] & 0b111111) >> 1)
          hour   = ((buffer[2] & 0b1) << 4) | (buffer[3] >> 4)
          min    = ((buffer[3] & 0b1111) << 2) | (buffer[4] >> 6)
          sec    = ((buffer[4] & 0b111111))

          Time.local(year, month, day, hour, min, sec)
        end


        ### IMPORT METHODS

        # rubocop:disable Naming/UncommunicativeMethodParamName
        def null=(_)
          @data = nil
        end
        # rubocop:enable Naming/UncommunicativeMethodParamName


        def shunt=(value)
          @data = value
        end


        def string=(value)
          @data = "#{value}\000"
        end


        def int=(value)
          @data = [value].pack('I')
        end


        def short=(value)
          @data = [value].pack('S')
        end


        def ascii=(value)
          @data = [value].pack('H*')
        end


        def date=(value)
          raise ArgumentError, "Expected: Time, String or Integer, got: '#{value.class}'." unless [Time, String, Integer].include?(value.class)

          value = Time.parse(value) if value.is_a?(String)
          value = Time.at(value) if value.is_a?(Integer)

          sec, min, hour, day, month, year = value.to_a

          @data = [
            0x0000FFFF & ((year >> 6) & 0x0000003F),
            0x0000FFFF & (((year & 0x0000003f) << 2) | ((month >> 2) & 0x00000003)),
            0x0000FFFF & (((month & 0x00000003) << 6) | ((day & 0x0000001F) << 1) | ((hour >> 4) & 0x00000001)),
            0x0000FFFF & (((hour & 0x0000000F) << 4) | ((min >> 2) & 0x0000000F)),
            0x0000FFFF & (((min & 0x00000003) << 6) | (sec & 0x0000003F)),
          ].pack('<C5')
        end

    end
  end
end
