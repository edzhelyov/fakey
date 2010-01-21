module Fkey #:nodoc:
  module PostgreSQLAdapter 
    def add_foreign_key(to_table, column, options={})
      to_table = options[:references] if options[:references]
      res = "FOREIGN KEY(#{quote_column_name(column)}) REFERENCES #{quote_table_name(to_table)}"
      res += "(#{options[:referenced_column]})" if options[:referenced_column]
      res
    end
    
    # Adds a new column to the named table.
    # See TableDefinition#column for details of the options you can use.
    def add_column_with_foreign_key(table_name, column_name, type, options = {})
      default = options[:default]
      notnull = options[:null] == false
      foreign_key = "REFERENCES #{quote_table_name(options[:references])}(#{quote_column_name(options[:referenced_column] || primary_key(options[:references]))})"
      
      # Add the column.
      execute("ALTER TABLE #{quote_table_name(table_name)} ADD COLUMN #{quote_column_name(column_name)} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])} #{foreign_key}")

      change_column_default(table_name, column_name, default) if options_include_default?(options)
      change_column_null(table_name, column_name, false, default) if notnull
    end
  end
end