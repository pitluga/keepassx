# frozen_string_literal: true

module Keepassx
  class Database
    module Loader

      attr_reader :header, :groups, :entries

      # rubocop:disable Metrics/MethodLength
      def initialize(opts)
        @password = nil
        @groups   = []
        @entries  = []
        raw_db    = ''

        if opts.is_a?(File)
          @path  = opts.path
          raw_db = read_file(opts)
          load_database(raw_db)

        elsif opts.is_a?(String)
          @path  = opts
          raw_db = read_file(opts) if File.exist?(opts)
          load_database(raw_db)

        elsif opts.is_a?(Array)
          @path = nil
          load_database(raw_db)
          opts.each { |item| parse_data(item) }
        end
      end
      # rubocop:enable Metrics/MethodLength


      # Unlock database.
      #
      # @param password [String] Database password.
      # @return [Boolean] Whether or not password validation successfull.
      # rubocop:disable Metrics/MethodLength
      def unlock(password, keyfile = nil)
        return true unless locked?

        # Store password as we'll need it to dump/save database
        @password = password
        keyfile_data = keyfile ? read_file(keyfile) : nil

        # Uncrypt database
        final_key  = header.final_key(password, keyfile_data)
        @payload   = decrypt_payload(@encrypted_payload, final_key)
        payload_io = StringIO.new(@payload)

        # Load it
        groups   = Group.extract_from_payload(header, payload_io)
        @groups  = initialize_groups(groups)
        @entries = Entry.extract_from_payload(header, payload_io)

        # Make groups <-> entries association
        @entries.each do |entry|
          group = @groups.detect { |g| g.id == entry.group_id }
          group.entries << entry
          entry.group = group
        end

        @locked = false

        true
      rescue OpenSSL::Cipher::CipherError
        false
      end
      # rubocop:enable Metrics/MethodLength


      # Get actual payload checksum.
      #
      # @return [String]
      def checksum
        Digest::SHA256.digest(payload)
      end


      def payload
        @payload ||= initialize_payload
      end


      # Get Entries and Groups total number.
      #
      # @return [Fixnum]
      def length
        length = 0
        [@groups, @entries].each do |items|
          items.each do |item|
            length += item.length
          end
        end
        length
      end


      private


        def read_file(file)
          read_method = File.respond_to?(:binread) && :binread || :read
          File.send(read_method, file)
        end


        def load_database(db)
          if db.empty?
            @header            = Header.new
            @encrypted_payload = ''
            @locked            = false
          else
            @header            = Header.new(db[0..124])
            @encrypted_payload = db[124..-1]
            @locked            = true
          end

          @locked
        end


        # See spec/fixtures/test_data_array.yaml for data example
        # rubocop:disable Metrics/MethodLength
        def parse_data(opts)
          groups  = opts[:groups]  || []
          entries = opts[:entries] || []
          parent  = opts[:parent]

          # Remove groups and entries from options, so new group could be
          # initialized from incoming Hash
          fields          = Keepassx::Group.fields
          group_opts      = opts.select { |k, _| fields.include?(k.to_s) }
          group           = add_group group_opts
          group.parent    = parent

          entries.each do |e|
            add_entry e.merge(group: group)
          end

          # Recursively proceed each child group
          groups.each do |g|
            parse_data g.merge(parent: group)
          end
        end
        # rubocop:enable Metrics/MethodLength


        def decrypt_payload(payload, final_key)
          Keepassx::AESCrypt.decrypt(payload, final_key, header.encryption_iv, 'AES-256-CBC')
        end


        def encrypt_payload(payload, final_key)
          Keepassx::AESCrypt.encrypt(payload, final_key, header.encryption_iv, 'AES-256-CBC')
        end


        # Set parents for groups
        #
        #  @param list [Array] Array of groups.
        #  @return [Array] Updated array of groups.
        # rubocop:disable Metrics/MethodLength
        def initialize_groups(list)
          list.each_with_index do |group, index|
            previous_group = index == 0 ? nil : list[index - 1]

            # If group is first entry or has level equal 0,
            # it gets parent set to nil
            if previous_group.nil? || group.level == 0
              group.parent = nil

            # If group has same level than the previous group,
            # then is has the same parent
            elsif group.level == previous_group.level
              group.parent = previous_group.parent

            # If group has level greater than parent's level by one,
            # it gets parent set to the first previous group with level less
            # than group's level by one
            elsif group.level == previous_group.level + 1
              group.parent = previous_group

            # If group has level less than or equal the level of the previous
            # group and its level is no less than zero, then need to backward
            # search for the first group which level is less than group's
            # level by 1 and set it as a parent of the group
            elsif group.level > 0 && group.level <= previous_group.level
              group.parent = (index - 2).downto 0 do |i|
                parent_candidate = list[i]
                break parent_candidate if parent_candidate.level + 1 == group.level
              end

            # Invalid level
            else
              raise "Unexpected level '#{group.level}' for group '#{group.name}'"
            end
          end

          list
        end
        # rubocop:enable Metrics/MethodLength


        def initialize_payload
          result = +''
          @groups.each { |group| result << group.encode }
          @entries.each { |entry| result << entry.encode }
          result
        end

    end
  end
end
