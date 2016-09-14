module Keepassx
  module Field
    class Entry < Base

      def self.fields_description
        @fields_description ||= [
          [0x0, 'ignored',         :null],
          [0x1, 'id',              :ascii],
          [0x2, 'group_id',        :int],
          [0x3, 'icon',            :int],
          [0x4, 'name',            :string],
          [0x5, 'url',             :string],
          [0x6, 'username',        :string],
          [0x7, 'password',        :string],
          [0x8, 'notes',           :string],
          [0x9, 'creation_time',   :date],
          [0xa, 'last_mod_time',   :date],
          [0xb, 'last_acc_time',   :date],
          [0xc, 'expiration_time', :date],
          [0xd, 'binary_desc',     :string],
          [0xe, 'binary_data',     :shunt],
          [0xFFFF, 'terminator',   :null]
        ]
      end

    end
  end
end
