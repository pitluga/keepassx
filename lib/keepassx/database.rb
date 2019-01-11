# frozen_string_literal: true

module Keepassx
  class Database

    include Database::Dumper
    include Database::Loader
    include Database::Finder


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


    # Add new group to database.
    #
    # @param opts [Hash] Options that will be passed to Keepassx::Group#new.
    # @return [Keepassx::Group]
    # rubocop:disable Metrics/MethodLength
    def add_group(opts)
      raise ArgumentError, "Expected Hash or Keepassx::Group, got #{opts.class}" unless valid_group?(opts)

      if opts.is_a?(Keepassx::Group)
        # Assign parent group
        parent = opts.parent
        index  = last_sibling_index(parent) + 1
        @groups.insert(index, opts)

        # Increment counter
        header.groups_count += 1

        # Return group
        opts

      elsif opts.is_a?(Hash)
        opts = deep_copy(opts)
        opts = build_group_options(opts)

        # Create group
        group = create_group(opts)

        # Increment counter
        header.groups_count += 1

        # Return group
        group
      end
    end
    # rubocop:enable Metrics/MethodLength


    # Add new entry to database.
    #
    # @param opts [Hash] Options that will be passed to Keepassx::Entry#new.
    # @return [Keepassx::Entry]
    def add_entry(opts)
      raise ArgumentError, "Expected Hash or Keepassx::Entry, got #{opts.class}" unless valid_entry?(opts)

      if opts.is_a?(Keepassx::Entry)
        # Add entry
        @entries << opts

        # Increment counter
        header.entries_count += 1

        # Return entry
        opts

      elsif opts.is_a?(Hash)
        opts = deep_copy(opts)
        opts = build_entry_options(opts)

        # Create entry
        entry = create_entry(opts)

        # Increment counter
        header.entries_count += 1

        # Return entry
        entry
      end
    end


    def delete_group(item)
      # Get group entries and delete them
      group_entries = entries.select { |e| e.group == item }
      group_entries.each { |e| delete_entry(e) }

      # Recursively delete ancestor groups
      group_ancestors = groups.select { |g| g.parent == item }
      group_ancestors.each { |g| delete_group(g) }

      item = groups.delete(item)
      header.groups_count -= 1
      item
    end


    def delete_entry(item)
      item = entries.delete(item)
      header.entries_count -= 1
      item
    end


    private


      # Make deep copy of Hash
      def deep_copy(opts)
        Marshal.load Marshal.dump(opts)
      end


      # Get next group ID number.
      #
      # @return [Fixnum]
      def next_group_id
        if @groups.empty?
          # Start each time from 1 to make sure groups get the same id's for the
          # same input data
          1
        else
          id = @groups.last.id
          loop do
            id += 1
            break id if @groups.find { |g| g.id == id }.nil?
          end
        end
      end


      # Retrieves last sibling index
      #
      #  @param parent [Keepassx::Group] Last sibling group.
      #  @return [Integer] index Group index.
      def last_sibling_index(parent)
        return -1 if groups.empty?

        if parent.nil?
          parent_index  = 0
          sibling_level = 1
        else
          parent_index  = groups.find_index(parent)
          sibling_level = parent.level + 1
        end

        raise "Could not find group #{parent.name}" if parent_index.nil?

        (parent_index..(header.groups_count - 1)).each do |i|
          break i unless groups[i].level == sibling_level
        end
      end


      def create_group(opts = {})
        group = Keepassx::Group.new(opts)
        if group.parent.nil?
          @groups << group
        else
          index = last_sibling_index(group.parent) + 1
          @groups.insert(index, group)
        end
        group
      end


      def build_group_options(opts = {})
        opts[:id] = next_group_id unless opts.key?(:id)

        # Replace parent, which is specified by symbol with actual group
        if opts[:parent].is_a?(Symbol)
          group = find_group(opts[:parent])
          raise "Group #{opts[:parent].inspect} does not exist" if group.nil?

          opts[:parent] = group
        end
        opts
      end


      def create_entry(opts = {})
        entry = Keepassx::Entry.new(opts)
        @entries << entry
        entry
      end


      # rubocop:disable Metrics/MethodLength, Style/SafeNavigation
      def build_entry_options(opts = {})
        if opts[:group]
          if opts[:group].is_a?(String) || opts[:group].is_a?(Hash)
            group = find_group(opts[:group])
            raise "Group #{opts[:group].inspect} does not exist" if group.nil?

            opts[:group] = group
            opts[:group_id] = group.id
          elsif opts[:group].is_a?(Keepassx::Group)
            opts[:group_id] = opts[:group].id
          end

        elsif opts[:group_id] && opts[:group_id].is_a?(Integer)
          group = find_group(id: opts[:group_id])
          raise "Group #{opts[:group_id].inspect} does not exist" if group.nil?

          opts[:group] = group
        end
        opts
      end
      # rubocop:enable Metrics/MethodLength, Style/SafeNavigation


      def valid_group?(object)
        object.is_a?(Keepassx::Group) || object.is_a?(Hash)
      end


      def valid_entry?(object)
        object.is_a?(Keepassx::Entry) || object.is_a?(Hash)
      end

  end
end
