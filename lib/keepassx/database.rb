module Keepassx
  class Database

    attr_reader :header, :groups, :entries

    def self.open(path)
      content = File.respond_to?(:binread) ? File.binread(path) : File.read(path)
      self.new(content)
    end

    def initialize(raw_db)
      @header = Header.new(raw_db[0..124])
      @encrypted_payload = raw_db[124..-1]
    end

    def entry(title)
      @entries.detect { |e| e.title == title }
    end

    def unlock(master_password)
      @final_key = header.final_key(master_password)
      decrypt_payload
      payload_io = StringIO.new(@payload)
      @groups = Group.extract_from_payload(header, payload_io)
      @entries = Entry.extract_from_payload(header, payload_io)
      true
    rescue OpenSSL::Cipher::CipherError
      false
    end

    def search(pattern)
      backup = groups.detect { |g| g.name == "Backup" }
      backup_group_id = backup && backup.group_id
      entries.select { |e| e.group_id != backup_group_id && e.title.force_encoding('UTF-8') =~ /#{pattern}/i }
    end

    def valid?
      @header.valid?
    end

    def decrypt_payload
      @payload = AESCrypt.decrypt(@encrypted_payload, @final_key, header.encryption_iv, 'AES-256-CBC')
    end
  end
end
