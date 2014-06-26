# The keepass file header.
#
# From the KeePass doc:
#
# Database header: [DBHDR]
#
# [ 4 bytes] DWORD    dwSignature1  = 0x9AA2D903
# [ 4 bytes] DWORD    dwSignature2  = 0xB54BFB65
# [ 4 bytes] DWORD    dwFlags
# [ 4 bytes] DWORD    dwVersion       { Ve.Ve.Mj.Mj:Mn.Mn.Bl.Bl }
# [16 bytes] BYTE{16} aMasterSeed
# [16 bytes] BYTE{16} aEncryptionIV
# [ 4 bytes] DWORD    dwGroups        Number of groups in database
# [ 4 bytes] DWORD    dwEntries       Number of entries in database
# [32 bytes] BYTE{32} aContentsHash   SHA-256 hash value of the plain contents
# [32 bytes] BYTE{32} aMasterSeed2    Used for the dwKeyEncRounds AES
#                                     master key transformations
# [ 4 bytes] DWORD    dwKeyEncRounds  See above; number of transformations
#
# Notes:
#
# - dwFlags is a bitmap, which can include:
#   * PWM_FLAG_SHA2     (1) for SHA-2.
#   * PWM_FLAG_RIJNDAEL (2) for AES (Rijndael).
#   * PWM_FLAG_ARCFOUR  (4) for ARC4.
#   * PWM_FLAG_TWOFISH  (8) for Twofish.
# - aMasterSeed is a salt that gets hashed with the transformed user master key
#   to form the final database data encryption/decryption key.
#   * FinalKey = SHA-256(aMasterSeed, TransformedUserMasterKey)
# - aEncryptionIV is the initialization vector used by AES/Twofish for
#   encrypting/decrypting the database data.
# - aContentsHash: "plain contents" refers to the database file, minus the
#   database header, decrypted by FinalKey.
#   * PlainContents = Decrypt_with_FinalKey(DatabaseFile - DatabaseHeader)
module Keepassx
  class Header

    ENCRYPTION_FLAGS = [
       [1 , 'SHA2'    ],
       [2 , 'Rijndael'],
       [2 , 'AES'     ],
       [4 , 'ArcFour' ],
       [8 , 'TwoFish' ]
    ]

    attr_reader :encryption_iv
    attr_reader :ngroups, :nentries

    def initialize(header_bytes)
      @signature1 = header_bytes[0..4].unpack('L*').first
      @signature2 = header_bytes[4..8].unpack('L*').first
      @flags   = header_bytes[8..12].unpack('L*').first
      @version = header_bytes[12..16].unpack('L*').first
      @master_seed = header_bytes[16...32]
      @encryption_iv = header_bytes[32...48]
      @ngroups = header_bytes[48..52].unpack('L*').first
      @nentries = header_bytes[52..56].unpack('L*').first
      @contents_hash = header_bytes[56..88]
      @master_seed2 = header_bytes[88...120]
      @rounds = header_bytes[120..-1].unpack('L*').first
    end

    def valid?
      @signature1 == 0x9AA2D903 && @signature2 == 0xB54BFB65
    end

    def encryption_type
      ENCRYPTION_FLAGS.each do |(flag_mask, encryption_type)|
        return encryption_type if @flags & flag_mask
      end
      'Unknown'
    end

    def final_key(master_key, keyfile_data=nil)
      key = Digest::SHA2.new.update(master_key).digest

      if keyfile_data
        if keyfile_data.size == 64 # Hex encoded key
          keyfile_hash = [keyfile_data].pack("H*")
        elsif keyfile_data.size == 32 # Raw key
          keyfile_hash = keyfile_data
        else
          keyfile_hash = Digest::SHA2.new.update(keyfile_data).digest
        end

        if master_key == ""
          key = keyfile_hash
        else
          key = Digest::SHA2.new.update(key + keyfile_hash).digest
        end
      end

      aes = OpenSSL::Cipher::Cipher.new('AES-256-ECB')
      aes.encrypt
      aes.key = @master_seed2
      aes.padding = 0

      @rounds.times do
        key = aes.update(key) + aes.final
      end

      key = Digest::SHA2.new.update(key).digest
      key = Digest::SHA2.new.update(@master_seed + key).digest
      key
    end
  end
end
