# frozen_string_literal: true

module Keepassx
  class Database
    module Dumper

      # Dump Array representation of database.
      #
      # @return [Array]
      def to_a(opts = {})
        find_groups(level: 0).map { |group| build_branch(group, opts) }
      end


      # Dump YAML representation of database.
      #
      # @return [String]
      def to_yaml(opts = {})
        YAML.dump to_a(opts)
      end


      # Save database to file storage
      #
      # @param password [String] Password the database will be encoded with.
      # @return [Fixnum]
      def save(opts = {})
        path     = opts.delete(:path) { nil }
        password = opts.delete(:password) { nil }

        new_path     = path || @path
        new_password = password || @password

        raise ArgumentError, 'File path is not set' if new_path.nil?
        raise ArgumentError, 'Password is not set' if new_password.nil?

        File.open(new_path, 'wb') do |file|
          file.write dump(new_password)
        end
      end


      private


        # Get raw encoded database.
        #
        # @param password [String] Password the database will be encoded with.
        # @param key_file [String] Path to key file.
        # @return [String]
        def dump(password)
          final_key = header.final_key(password)
          initialize_payload
          header.content_hash = checksum
          @encrypted_payload  = encrypt_payload(@payload, final_key)
          data = header.encode << @encrypted_payload.to_s
          data
        end


        # Organize descendants in proper structure for given group.
        # @param [Keepassx::Group] group Root group, branch is build for.
        def build_branch(group, opts = {})
          group_hash = group.to_hash(opts)

          group_entries = find_entries(group: group)
          descendant_groups = find_groups(parent: group)

          unless group_entries.nil?
            group_hash['entries'] = []
            group_entries.each { |e| group_hash['entries'] << e.to_hash(opts) }
          end

          unless descendant_groups.nil?
            group_hash['groups'] = []
            # Recursively build branch for descendant groups
            descendant_groups.each { |g| group_hash['groups'] << build_branch(g, opts) }
          end

          group_hash
        end

    end
  end
end
