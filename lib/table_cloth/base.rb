module TableCloth
  class Base
    attr_reader :collection, :view

    def initialize(collection, view)
      @collection = collection
      @view       = view
    end

    def column_names
      columns.each_with_object([]) do |(column_name, column), names|
        names << column.human_name
      end
    end

    def columns
      self.class.columns.each_with_object({}) do |(column_name, column), columns|
        columns[column_name] = column if column.available?(self)
      end
    end

    def has_actions?
      self.class.has_actions?
    end

    class << self
      def presenter(klass=nil)
        if klass
          @presenter = klass
        else
          @presenter || (superclass.respond_to?(:presenter) ? superclass.presenter : raise("No Presenter"))
        end
      end

      def column(*args, &block)
        options = args.extract_options! || {}
        options[:proc] = block if block_given?

        column_class = options.delete(:using) || Column

        args.each do |name|
          add_column name, column_class.new(name, options)
        end
      end

      def columns
        @columns ||= {}
        if superclass.respond_to? :columns
          @columns = superclass.columns.merge(@columns)
        end

        @columns
      end

      def add_column(name, column)
        @columns ||= {}
        @columns[name] = column
      end

      def action(*args, &block)
        options        = args.extract_options! || {}
        options[:proc] = block if block_given?

        add_action Action.new(options)
      end

      def add_action(action)
        unless has_actions?
          columns[:actions] = Columns::Action.new(:actions)
        end

        columns[:actions].actions << action
        action
      end

      def has_actions?
        columns[:actions].present?
      end
    end
  end
end