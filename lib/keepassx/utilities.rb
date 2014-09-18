module Keepassx
  module Utilities


    private

    # Organize descendants in proper structure for given group.
    # @param [Keepassx::Group] group Root group, branch is build for.
    def build_branch group
      group_hash = group.to_hash
      group_entries = entries :group => group
      descendant_groups = groups :parent => group

      unless group_entries.nil?
        group_hash[:entries] = []
        entries.each { |e| group_hash[:entries] << e.to_hash }
      end

      unless descendant_groups.nil?
        group_hash[:groups] = []
        # Recursively build branch for descendant groups
        descendant_groups.each { |g| group_hash[:groups] << build_branch(g) }
      end

      group_hash
    end


    def deep_copy opts
      Marshal.load Marshal.dump opts # Make deep copy
    end


    def decrypt
      @payload = AESCrypt.decrypt @encrypted_payload, final_key,
          header.encryption_iv, 'AES-256-CBC'
      current_checksum = checksum
      unless current_checksum.eql? header.contents_hash
        raise Keepassx::HashError.new "Hash test failed, expected " \
            "#{header.contents_hash.inspect}, got #{current_checksum.inspect}"
      end

      @payload
    end


    def encrypt
      @encrypted_payload = AESCrypt.encrypt @payload, final_key,
          header.encryption_iv, 'AES-256-CBC'
    end


    def read opts
      read_method = File.respond_to?(:binread) && :binread || :read
      File.send read_method, opts

        # FIXME: Implement exceptions
    rescue IOError => e
      warn ">>>> IOError in database.rb"
      fail
    rescue SystemCallError => e
      warn ">>>> SystemCallError in database.rb"
      fail
    end


    def final_key
      fail "No master password specified" if password.nil?

      key_file_data = nil
      if File.exists? key_file
        read_method   = File.respond_to?(:binread) ? :binread : :read
        key_file_data = File.send read_method
      end unless key_file.nil?

      header.final_key(password, key_file_data)
    end


    def initialize_database raw_db
      if raw_db.empty?
        @header = Header.new
        @locked = false
      else
        @header = Header.new raw_db[0..124]
        @encrypted_payload = raw_db[124..-1]
      end

      @locked
    end


    # Set parents for groups
    #
    #  @param list [Array] Array of groups.
    #  @return [Array] Updated array of groups.
    def initialize_groups list

      list.each_with_index do |group, index|

        if index.eql? 0
          previous_group = nil
        else
          previous_group = list[index - 1]
        end

        # If group is first entry or has level equal 0,
        # it gets parent set to nil
        if previous_group.nil? or group.level.eql? 0
          group.parent = nil

        # If group has level greater than parent's level by one,
        # it gets parent set to the first previous group with level less
        # than group's level by one
        elsif group.level == previous_group.level + 1 or
            group.level == previous_group.level

          group.parent = previous_group

          # If group has level less than or equal the level of the previous
          # group and its level is no less than zero, then need to backward
          # search for the first group which level is less than group's
          # level by 1 and set it as a parent of the group
        elsif 0 < group.level and group.level <= previous_group.level
          group.parent = (index - 2).downto 0 do |i|
            parent_candidate = list[i]
            break parent_candidate if parent_candidate.level - 1 == group.level
          end

          # Invalid level
        else
          fail "Unexpected level '#{group.level}' for group '#{group.title}'"
        end

      end

      @groups = list
    end


    def initialize_payload
      result = ''
      @groups.each { |group| result << group.encode }
      @entries.each { |entry| result << entry.encode }
      result
    end


    def payload
      @payload ||= initialize_payload
    end


    # Retrieves last sibling index
    #
    #  @param parent [Keepassx::Group] Last sibling group.
    #  @return [Integer] index Group index.
    def last_sibling_index parent

      if groups.empty?
        return -1

      elsif parent.nil?
        parent_index  = 0
        sibling_level = 1

      else
        parent_index  = groups.find_index parent
        sibling_level = parent.level + 1

      end

      fail "Could not find group #{parent.title}" if parent_index.nil?

      (parent_index..(header.group_number - 1)).each do |i|
        break i unless groups[i].level.eql? sibling_level
      end

    end


    # FIXME: Rename the method
    # See spec/fixtures/test_data_array.yaml for data example
    def parse_data_array opts
      groups, entries = opts[:groups], opts[:entries]

      # Remove groups and entries from options, so new group could be
      # initialized from incoming Hash
      fields          = Keepassx::Group.fields
      group_opts      = opts.reject { |k, _| !fields.include? k }
      group           = add_group group_opts

      entries.each do |e|
        entry = e.clone
        add_entry entry.merge(:group => group)
      end unless entries.nil?

      # Recursively proceed each child group
      groups.each { |g| parse_data_array g } unless groups.nil?

    end


    def delete_entry item
      item = entries.delete item
      header.entry_number -= 1
      item
    end


    # Recursively delete group
    def delete_group item
      group_entries = entries.select { |e| e.group.equal? item }
      # Delete entries, which belongs to group
      group_entries.each { |e| delete_entry e }

      group_ancestors = groups.select { |g| g.parent.equal? item }
      # Recursively delete ancestor groups
      group_ancestors.each { |g| delete_group g }

      item = groups.delete item
      header.group_number -= 1
      item
    end

  end
end
