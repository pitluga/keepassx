module Keepassx
  class GroupField
    include Field

    FIELD_TYPES = [
        [0x0, 'ignored', :null],
        [0x1, 'groupid', :int],
        [0x2, 'group_name', :string],
        [0x3, 'creation_time', :date],
        [0x4, 'lastmod_time', :date],
        [0x5, 'lastacc_time', :date],
        [0x6, 'expire_time', :date],
        [0x7, 'imageid', :int],
        [0x8, 'level', :short],
        [0x9, 'flags', :int],
        [0xFFFF, 'terminator', :null]
    ]

    attr_reader :name, :data_type, :type_code

  end
end
