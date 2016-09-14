module Keepassx
  module Field
    class Group < Base

      def self.fields_description
        @fields_description ||= [
          [0x0, 'ignored',         :null],
          [0x1, 'id',              :int],
          [0x2, 'name',            :string],
          [0x3, 'creation_time',   :date],
          [0x4, 'last_mod_time',   :date],
          [0x5, 'last_acc_time',   :date],
          [0x6, 'expiration_time', :date],
          [0x7, 'icon',            :int],
          [0x8, 'level',           :short],
          [0x9, 'flags',           :int],
          [0xFFFF, 'terminator',   :null]
        ]
      end

    end
  end
end
