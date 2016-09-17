module Keepassx
  class Database
    module Finder

      # Get the first matching entry.
      #
      # @return [Keepassx::Entry]
      def find_entry(opts = {}, &block)
        entries = find_entries(opts, &block)
        filter_list(entries)
      end


      # Get the first matching group.
      #
      # @return [Keepassx::Group]
      def find_group(opts = {}, &block)
        groups = find_groups(opts, &block)
        filter_list(groups)
      end


      # Get all matching groups.
      #
      # @param opts [Hash]
      # @return [Array<Keepassx::Group>]
      def find_groups(opts = {}, &block)
        find :group, opts, &block
      end


      # Get all matching entries.
      #
      # @return [Array<Keepassx::Entry>]
      def find_entries(opts = {}, &block)
        find :entry, opts, &block
      end


      def search(pattern)
        backup = groups.find { |g| g.name == "Backup" }
        backup_group_id = backup && backup.id
        entries.select { |e| e.group_id != backup_group_id && e.name =~ /#{pattern}/i }
      end


      private


        # Search for items, using AND statement for the search conditions
        #
        # @param item_type [Symbol] Can be :entry or :group.
        # @param opts [Hash] Search options.
        # @return [Keepassx::Group, Keepassx::Entry]
        def find(item_type, opts = {}, &block)
          item_list = (item_type == :entry) ? @entries : @groups
          items     = opts.empty? ? item_list : deep_search(item_list, opts)

          return items unless block_given?

          items.each do |i|
            yield i
          end
        end


        def deep_search(item_list, opts = {})
          opts = { name: opts.to_s } if opts.is_a?(String) || opts.is_a?(Symbol)

          match_number = opts.length

          items = []
          opts.each do |k, v|
            items += Array(item_list.select { |e| e.send(k) == v })
          end

          buffer = Hash.new 0
          items.each do |e|
            buffer[e] += 1
          end

          # Select only items which matches all conditions
          items = []
          buffer.each do |k, v|
            items << k if v == match_number
          end

          items
        end


        def filter_list(list)
          list.empty? ? nil : list.first
        end

    end
  end
end
