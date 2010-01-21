module Fkey
  #TODO: support for change_table, add_column and etc. that depend on ActiveRecord::ConnectionAdapters::Table
  # module Table
  #   def self.included(base)
  #     base.class_eval do
  #       # alias_method_chain :to_sql, :foreign_keys
  #       alias_method_chain :references, :foreign_keys
  #       alias_method_chain :belongs_to, :foreign_keys
  #     end
  #   end
  # 
  #   def references_with_foreign_keys(*args)
  #     options = args.extract_options!
  #     polymorphic = options.delete(:polymorphic)
  #     args.each do |col|
  #       @base.add_column(@table_name, "#{col}_id", :integer, options)
  #       @base.add_foreign_key(@table_name, col, "#{col}_id", options)
  #       @base.add_column(@table_name, "#{col}_type", :string, polymorphic.is_a?(Hash) ? polymorphic : options) unless polymorphic.nil?
  #     end
  #   end
  #   alias :belongs_to_with_foreign_keys :references_with_foreign_keys
  # end
  
  module TableDefinition
    def self.included(base)
      base.class_eval do
        alias_method_chain :to_sql, :foreign_keys
        alias_method_chain :references, :foreign_keys
        alias_method_chain :belongs_to, :foreign_keys
      end
    end
    
    def references_with_foreign_keys(*args)
      options = args.extract_options!
      polymorphic = options.delete(:polymorphic)
      args.each do |col|
        column_name =  options[:column] || "#{col}_id"
        column_database_type = options[:type] || :integer
        column(column_name, column_database_type, options)
        if polymorphic
          column("#{col}_type", :string, polymorphic.is_a?(Hash) ? polymorphic : options)
        else
          table_name = options[:references] || col.to_s.pluralize
          add_foreign_key(column_name, table_name, options)
        end
      end
    end
    alias :belongs_to_with_foreign_keys :references_with_foreign_keys
    
    def add_foreign_key(column_name,table_name,options)
      @foreign_keys ||= []
      @foreign_keys << {:column_name => column_name, :to_table => table_name, :options => options}
    end
    
    def to_sql_with_foreign_keys
      sql = to_sql_without_foreign_keys
      if @foreign_keys
        sql << ',' <<  @foreign_keys.map{|fk| @base.add_foreign_key(fk[:to_table],fk[:column_name],fk[:options])}.join(",")
      end
      sql
    end
  end
  
  module Table
    def self.included(base)
      base.class_eval do
        alias_method_chain :references, :foreign_keys
        alias_method_chain :belongs_to, :foreign_keys
      end
    end

    def references_with_foreign_keys(*args)
      options = args.extract_options!
      polymorphic = options.delete(:polymorphic)
      args.each do |col|
        column_name =  options[:column] || "#{col}_id"
        column_database_type = options[:type] || :integer
        if polymorphic
          @base.add_column(@table_name, column_name, column_database_type, options)
          @base.add_column(@table_name, "#{col}_type", :string, polymorphic.is_a?(Hash) ? polymorphic : options) 
        else
          options[:references] ||= col.to_s.pluralize
          @base.add_column_with_foreign_key(@table_name, column_name, column_database_type, options)
        end
      end
    end
    alias :belongs_to_with_foreign_keys :references_with_foreign_keys
  end
end