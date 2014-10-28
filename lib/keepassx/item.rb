module Keepassx

  module Item


    def initialize _
      @fields = []
    end

    def length
      @fields.map(&:length).reduce(&:+)
    end


    def encode
      buffer = ''
      # FIXME: Check if terminator field not in @fields
      @fields.each do |field|
        buffer << field.encode
      end
      buffer
    end


    def to_hash
      result = {}
      self.class.fields.each do |field|

        filed = field.to_sym
        if self.respond_to? field
          data = self.send field
          # Skip empty value
          if data.respond_to? :empty?
            result[field] = data unless data.empty?
          else
            unless data.nil?
              # FIXME: Implement field export method
              if data.is_a? Time
                result[field] = data.to_i
              else
                result[field] = data
              end
            end
          end
        end

      end
      # warn "result: #{result}"
      result
    end


    def terminator= _
      self.class::FIELD_CLASS.new :name => :terminator
    end


    def inspect
      output = "<#{self.class} "
      default_fields.each_key do |field_name|
        if field_name.eql? :password
          output << ', password=[FILTERED]'
        else
          output << ", #{field_name}=#{self.send(field_name)}" unless
              field_name.eql? :terminator
        end
      end
      output << '>'
    end


    def to_xml
      section_name = (self.is_a? Keepassx::Group) && 'group' || 'entry'
      main_section = REXML::Element.new section_name
      default_fields.each_key do |field_name|
        unless field_name.eql? :terminator
          filed_section = main_section.add_element field_name.to_s
          filed_section.text = self.send field_name
        end
      end

      main_section
    end


    private

    def decode(buffer)
      @fields = []
      loop do
        field = self.class::FIELD_CLASS.new(buffer)
        @fields << field
        break if field.terminator?
      end
      @fields
    end


    def set(name, value)
      field = @fields.detect { |field| field.name.eql? name.to_s }
      if field.nil?
        field = self.class::FIELD_CLASS.new :name => name, :data => value
      else
        field.data = value
      end
      field
    end


    def get(name)
      field = @fields.detect { |field| field.name.eql? name.to_s }
      # if field.nil?
      #   # FIXME: Put proper field name into 'Field doesn't exists' exception
      #   # fail "Field '#{name}' doesn't exists or not yet created"
      # else
      #   field.data
      # end
      field.data unless field.nil? # Return nil, if field doesn't exist
    end

  end
end
