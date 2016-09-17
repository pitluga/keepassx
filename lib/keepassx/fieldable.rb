module Keepassx
  class Fieldable

    def initialize(payload, &block)
      @fields = []

      if payload.is_a?(StringIO)
        @fields = decode_payload(payload)
      elsif payload.is_a?(Hash)
        yield
      else
        raise ArgumentError, "Expected StringIO or Hash, got #{payload.class}"
      end
    end


    class << self

      def set_field_descriptor(klass)
        @field_descriptor = klass
        create_fieldable_methods(klass.fields_description)
      end


      def field_descriptor
        @field_descriptor
      end


      def create_fieldable_methods(methods)
        methods.each do |_, method, _|
          define_method method do
            get method
          end

          define_method "#{method}=" do |v|
            set method, v
          end
        end
      end


      # Return the list of fields' names
      def fields
        @fields ||= field_descriptor.fields_description.map { |_, name, _| name }
      end

    end


    def fields
      @fields
    end


    def length
      fields.map(&:length).reduce(&:+)
    end


    def to_hash(opts = {})
      skip_date = opts.fetch(:skip_date, false)

      result = {}
      fields.each do |field|
        next if excluded_field?(field.name)
        next if date_field?(field.name) && skip_date
        result[field.name] = field.data
      end
      result
    end


    def encode
      buffer = ''
      fields.each do |field|
        buffer << field.encode
      end
      buffer
    end


    def inspect
      output = []
      default_fields.each_key do |field_name|
        if field_name == :password
          output << 'password=[FILTERED]'
        else
          output << "#{field_name}=#{self.send(field_name)}" unless field_name == :terminator
        end
      end
      "<#{self.class} #{output.join(', ')}>"
    end


    private


      def decode_payload(payload)
        fields = []
        begin
          field = self.class.field_descriptor.new(payload)
          fields << field
        end while not field.terminator?
        fields
      end


      def build_payload(payload)
        fields = []
        default_fields.merge(payload).each do |k, v|
          fields << self.class.field_descriptor.new({ name: k, data: v })
        end
        fields
      end


      def valid_integer?(field)
        field.is_a?(Integer)
      end


      def valid_string?(field)
        field.is_a?(String) && !field.empty?
      end


      def get(name)
        field = @fields.find { |field| field.name == name.to_s }
        field.data unless field.nil?
      end


      def set(name, value)
        field = @fields.find { |field| field.name == name.to_s }
        if field.nil?
          field = self.class.field_descriptor.new({ name: name, data: value })
          @fields << field
        else
          field.data = value
        end
        field
      end


      def excluded_field?(field)
        exclusion_list.include?(field)
      end


      def exclusion_list
        %w(terminator)
      end


      def date_field?(field)
        %w(creation_time last_mod_time last_acc_time expiration_time).include?(field)
      end

  end
end
