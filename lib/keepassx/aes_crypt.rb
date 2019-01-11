# frozen_string_literal: true

module Keepassx
  module AESCrypt
    module_function

    # rubocop:disable Naming/UncommunicativeMethodParamName
    def decrypt(encrypted_data, key, iv, cipher_type)
      aes = OpenSSL::Cipher.new(cipher_type)
      aes.decrypt
      aes.key = key
      aes.iv  = iv unless iv.nil?
      aes.update(encrypted_data) + aes.final
    end
    # rubocop:enable Naming/UncommunicativeMethodParamName


    # rubocop:disable Naming/UncommunicativeMethodParamName
    def encrypt(data, key, iv, cipher_type)
      aes = OpenSSL::Cipher.new(cipher_type)
      aes.encrypt
      aes.key = key
      aes.iv  = iv unless iv.nil?
      aes.update(data) + aes.final
    end
    # rubocop:enable Naming/UncommunicativeMethodParamName

  end
end
