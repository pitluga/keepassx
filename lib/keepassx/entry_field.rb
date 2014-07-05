module Keepassx
  class EntryField
    include Field

    FIELD_TYPES = [
        [0x0, 'ignored', :null],
        [0x1, 'uuid', :ascii],
        [0x2, 'groupid', :int],
        [0x3, 'imageid', :int],
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
        [0xFFFF, 'terminator', :null]
    ]

    attr_reader :name, :data_type, :type_code

  end
end
