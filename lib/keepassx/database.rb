module Keepassx
  class Database

    include Keepassx::Utilities

    # BACKUP_GROUP_OPTIONS = { :title => :Backup, :icon => 4, :id => 0 }

    attr_reader :header
    attr_accessor :password, :key_file, :path


    def self.open opts
      path = opts.to_s
      fail IOError, "File #{path} does not exist." unless File.exist? path
      db = self.new path
      return db unless block_given?
      yield db
    end


    def initialize opts

      raw_db, @groups, @entries, @locked = '', [], [], true

      if opts.is_a? File
        self.path = opts.path
        raw_db = read opts
        initialize_database raw_db

      elsif opts.is_a? String
        self.path = opts
        raw_db = read opts if File.exist? opts
        initialize_database raw_db

      elsif opts.is_a? REXML::Document
        # TODO: Implement import method
        fail NotImplementedError

      elsif opts.is_a? Array
        initialize_database '' # Pass empty data to get header initialized
        # Avoid opts change by parse_data_array method
        opts.each { |item| parse_data_array item }
        # initialize_payload # Make sure payaload is available for checksum

      else
        fail TypeError, "Expected one of the File, String, " \
            "REXML::Document or Hast, got #{opts.class}"
      end

    end


    # Get raw encoded database.
    #
    # @param password [String] Password the database will be encoded with.
    # @param key_file [String] Path to key file.
    # @return [String]
    def dump password = nil, key_file = nil
      # FIXME: Figure out what this is needed for
      # my $e = ($self->find_entries({title => 'Meta-Info', username => 'SYSTEM', comment => 'KPX_GROUP_TREE_STATE', url => '$'}))[0] || $self->add_entry({
      #     comment  => 'KPX_GROUP_TREE_STATE',
      #     title    => 'Meta-Info',
      #     username => 'SYSTEM',
      #     url      => '$',
      #     id       => '0000000000000000',
      #     group    => $g[0],
      #     binary   => {'bin-stream' => $bin},
      # });

      self.password = password unless password.nil?
      self.key_file = key_file unless key_file.nil?

      initialize_payload
      header.contents_hash = checksum
      encrypt

      header.encode << @encrypted_payload.to_s
    end


    # Save database to file storage
    #
    # @param password [String] Password the database will be encoded with.
    # @param key_file [String] Path to key file.
    # @return [Fixnum]
    def save password = nil, key_file = nil
      # TODO: Switch to rails style, i.e. save(:password => 'pass')
      fail TypeError, 'File path is not set' if path.nil?
      File.write path, dump(password, key_file)

    # FIXME: Implement exceptions
    rescue IOError => e
      warn ">>>> IOError in database.rb"
      fail
    rescue SystemCallError => e
      warn ">>>> SystemCallError in database.rb"
      fail
    end


    # Search for items, using AND statement for the search conditions
    #
    # @param item_type [Symbol] Can be :entry or :group.
    # @param opts [Hash] Search options.
    # @return [Keepassx::Group, Keepassx::Entry]
    def get item_type, opts = {}

      case item_type
        when :entry
          item_list = @entries
        when :group
          item_list = @groups
        else
          fail "Unknown item type '#{item_type}'"
      end

      if opts.empty?
        # Return all items if no selection condition was provided
        items = item_list

      else
        opts = { :title => opts.to_s } if opts.is_a? String or opts.is_a? Symbol

        match_number = opts.length
        items = []
        opts.each do |k, v|
          items += Array(item_list.select { |e| e.send(k).eql?(v) })
        end

        buffer = Hash.new 0
        items.each do |e|
          buffer[e] += 1
        end


        # Select only items which matches all conditions
        items = []
        buffer.each do |k, v|
          items << k if v.eql? match_number
        end
      end

      if block_given?
        items.each do |i|
          yield i
        end

      else
        items
      end

    end


    # Get first matching entry.
    #
    # @return [Keepassx::Entry]
    def entry opts = {}
      entries = get :entry, opts
      if entries.empty?
        nil
      else
        entries.first
      end

    end


    # Get all matching entries.
    #
    # @return [Array<Keepassx::Entry>]
    def entries opts = {}
      get :entry, opts
    end


    # Get first matching group.
    #
    # @return [Keepassx::Group]
    def group opts = {}
      groups = get :group, opts
      if groups.empty?
        nil
      else
        groups.first
      end

    end


    # Get all matching groups.
    #
    # @param opts [Hash]
    # @return [Array<Keepassx::Group>]
    def groups opts = {}
      get :group, opts
    end


    # Add new item to database.
    #
    # @param item [Symbol, Keepassx::Group, Keepassx::Entry] New item.
    # @return [Keepassx::Group, Keepassx::Entry]
    def add item, opts = {}
      if item.is_a? Symbol

        if item.eql? :group
          return add_group opts
        elsif item.eql? :entry
          return add_entry opts
        else
          fail "Unknown item type '#{item.to_s}'"
        end

      elsif item.is_a? Keepassx::Group
        return add_group item

      elsif item.is_a? Keepassx::Entry
        return add_entry item

      else
        fail "Could not add '#{item.inspect}'"
      end
    end


    # Add new group to database.
    #
    # @param opts [Hash] Options that will be passed to Keepassx::Group#new.
    # @return [Keepassx::Group]
    def add_group opts

      if opts.is_a? Hash
        opts = deep_copy opts
        opts[:id] = next_group_id unless opts.has_key? :id

        # Replace parent, which is specified by symbol with actual group
        if opts[:parent].is_a? Symbol
          group = self.group opts[:parent]
          fail "Group #{opts[:parent].inspect} does not exist" if group.nil?
          opts[:parent] = group
        end

        group = Keepassx::Group.new(opts)
        if group.parent.nil?
          @groups << group
        else
          @groups.insert last_sibling_index(group.parent) + 1, group
        end
        header.group_number += 1

        group
      elsif opts.is_a? Keepassx::Group
        # Assign parent group
        parent = opts.parent || nil
        @groups.insert last_sibling_index(parent) + 1, item
        header.group_number += 1
        opts

      else
        fail TypeError, "Expected Hash or Keepassx::Group, got #{opts.class}"
      end

    end


    # Add new entry to database.
    #
    # @param opts [Hash] Options that will be passed to Keepassx::Entry#new.
    # @return [Keepassx::Entry]
    def add_entry opts
      # FIXME: Add warnings and detailed description
      if opts.is_a? Hash
        opts = deep_copy opts

        # FIXME: Remove this feature as it has unpredictable behavior when groups with duplicate title are present
        if opts[:group].is_a? Symbol
          group = self.group opts[:group]
          fail "Group #{opts[:group].inspect} does not exist" if group.nil?
          opts[:group] = group
        end

        entry = Keepassx::Entry.new opts
        @entries << entry
        header.entry_number += 1
        entry

      elsif opts.is_a? Keepassx::Entry
        @entries << opts
        header.entry_number += 1
        opts
      else
        fail TypeError, "Expected Hash or Keepassx::Entry, got #{opts.class}"
      end
    end


    # Delete item from database.
    #
    # @param item [Keepassx::Group, Keepassx::Entry, Symbol] Item to delete.
    # @param opts [Hash] If first parameter is a Symbol, then this will be
    #  used to determine which item to delete.
    def delete item, opts = {}
      if item.is_a? Keepassx::Group
        delete_group item

      elsif item.is_a? Keepassx::Entry
        delete_entry item

      elsif item.is_a? Symbol
        if item.eql? :group
          delete_group group(opts)

        elsif item.eql? :entry
          delete_entry entry(opts)

        else
          fail "Unknown item type '#{item.to_s}'"
        end
      end

    end


    # Unlock database.
    #
    # @param password [String] Datbase password.
    # @param key_file [String] Key file path.
    # @return [Boolean] Whether or not password validation successfull.
    def unlock password, key_file = nil

      return true unless locked?

      self.password = password unless password.nil?
      self.key_file = key_file unless key_file.nil?
      decrypt
      payload_io = StringIO.new payload

      initialize_groups Group.extract_from_payload header, payload_io
      @entries = Entry.extract_from_payload header, groups, payload_io
      @locked = false
      true
    rescue OpenSSL::Cipher::CipherError
      false
    rescue Keepassx::MalformedDataError
      fail
    end



    # Search entry by title.
    #
    # @param pattern [String] Entry's title to search for.
    # @return [Keepassx::Entry]
    def search pattern
      # FIXME: Seqrch by any atribute by pattern
      backup = group 'Backup'

      entries.select do |e|
        e.group != backup && e.title =~ /#{pattern}/i
      end
    end


    # Check database validity.
    #
    # @return [Boolean]
    def valid?
      header.valid?
    end


    # Get lock state
    #
    # @return [Boolean]
    def locked?
      @locked
    end


    # Get Group/Entry index in storage.
    #
    # @return [Fixnum]
    def index v
      if v.is_a? Keepassx::Group
        groups.find_index v

      elsif v.is_a? Keepassx::Entry
        entries.find_index v

      else
        fail "Cannot get index for #{v.class}"

      end
    end


    # Get Enries and Groups total number.
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


    # Get actual payload checksum.
    #
    # @return [String]
    def checksum
      Digest::SHA256.digest payload
    end


    # Get next group ID number.
    #
    # @return [Fixnum]
    def next_group_id
      if groups.empty?
        # Start each time from 1 to make sure groups get the same id's for the
        # same input data
        1
      else
        id = groups.last.id
        loop do
          id += 1
          break id if groups.detect { |g| g.id.eql? id }.nil?
        end
      end
    end


    # Dump database in XML.
    #
    # @return [REXML::Document] XML database representation.
    def to_xml

      document = REXML::Document.new '<!DOCTYPE KEEPASSX_DATABASE><database/>'

      parent_element = document.root
      groups.each do |group|
        # xml = group.to_xml
        # parent_element = parent_element.add xml if group.parent.nil?
        section = parent_element.add group.to_xml
        entries(:group => group).each { |e| section.add e.to_xml }
        parent_element.add section
      end

      document
    end


    # Dump Array representation of database.
    #
    # @return [Array]
    def to_a
      result = []
      groups(:level => 0).each { |group| result << build_branch(group) }
      result
    end


    # Dump YAML representation of database.
    #
    # @return [String]
    def to_yaml
      YAML.dump to_a
    end
  end
end
