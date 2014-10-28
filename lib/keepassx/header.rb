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
        [1, 'SHA2'],
        [2, 'Rijndael'],
        [2, 'AES'],
        [4, 'ArcFour'],
        [8, 'TwoFish']
    ]

    FIELDS = [
        :signature1,
        :signature2,
        :flags,
        :version,
        :master_seed,
        :encryption_iv,
        :group_number,
        :entry_number,
        :contents_hash,
        :master_seed2,
        :rounds
    ]

    SIGNATURES = [0x9AA2D903, 0xB54BFB65]

    attr_accessor :group_number, :entry_number, :encryption_iv, :contents_hash
    attr_reader :signature1, :signature2, :flags, :version, :master_seed,
        :master_seed2, :rounds


    def initialize(header_bytes = nil)
      if header_bytes.nil?
        self.signature1, self.signature2 = SIGNATURES
        self.flags = 3 # SHA2 hashing, AES encryption
        self.version = 0x30002

        self.master_seed = SecureRandom.random_bytes(16)
        self.encryption_iv = SecureRandom.random_bytes(16)
        self.master_seed2 = SecureRandom.random_bytes(32)

        self.group_number = 0
        self.entry_number = 0
        self.rounds = 50000
      else
        header_bytes = StringIO.new header_bytes
        self.signature1 = header_bytes.read(4).unpack('L*').first
        self.signature2 = header_bytes.read(4).unpack('L*').first
        self.flags = header_bytes.read(4).unpack('L*').first
        self.version = header_bytes.read(4).unpack('L*').first
        self.master_seed = header_bytes.read(16)
        self.encryption_iv = header_bytes.read(16)
        self.group_number = header_bytes.read(4).unpack('L*').first
        self.entry_number = header_bytes.read(4).unpack('L*').first
        self.contents_hash = header_bytes.read(32)
        self.master_seed2 = header_bytes.read(32)
        self.rounds = header_bytes.read(4).unpack('L*').first
      end
    end


    def length
      length = 0
      FIELDS.each do |field|
        length += field.length
      end
      length
    end


    # Return encoded header
    #
    # @return [String] Encoded header representation.
    def encode
      [signature1].pack('L*') <<
          [signature2].pack('L*') <<
          [flags].pack('L*') <<
          [version].pack('L*') <<
          master_seed <<
          encryption_iv <<
          [group_number].pack('L*') <<
          [entry_number].pack('L*') <<
          contents_hash <<
          master_seed2 <<
          [rounds].pack('L*')

    end


    def valid?
      signature1 == SIGNATURES[0] && signature2 == SIGNATURES[1]
    end


    def encryption_type
      ENCRYPTION_FLAGS.each do |(flag_mask, encryption_type)|
        return encryption_type if flags & flag_mask
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
      aes.key = master_seed2
      aes.padding = 0

      rounds.times do
        key = aes.update(key) + aes.final
      end

      key = Digest::SHA2.new.update(key).digest
      Digest::SHA2.new.update(master_seed + key).digest

    end


    private

    attr_writer :signature1, :signature2, :flags, :version, :master_seed,
        :master_seed2, :rounds

  end
end
