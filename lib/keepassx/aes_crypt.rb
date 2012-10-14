module Keepassx
  module AESCrypt
    def self.decrypt(encrypted_data, key, iv, cipher_type)
      aes = OpenSSL::Cipher::Cipher.new(cipher_type)
      aes.decrypt
      aes.key = key
      aes.iv = iv unless iv.nil?
      aes.update(encrypted_data) + aes.final
    end

    def self.encrypt(data, key, iv, cipher_type)
      aes = OpenSSL::Cipher::Cipher.new(cipher_type)
      aes.encrypt
      aes.key = key
      aes.iv = iv unless iv.nil?
      aes.update(data) + aes.final
    end
  end
end
