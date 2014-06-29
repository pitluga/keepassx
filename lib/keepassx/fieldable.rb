module Keepassx
  module Fieldable

    def fields
      return @fields
    end

    def method_missing(name)
      @fields.detect { |field| field.name == name.to_s }.data.chomp("\000") rescue super
    end

    def field_names
      @fields.map &:name
    end
  end
end