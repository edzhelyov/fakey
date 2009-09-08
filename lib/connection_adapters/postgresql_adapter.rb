module Fkey #:nodoc:
  module PostgreSQLAdapter 
    def add_foreign_key(to_table, column, options={})
      to_table = options[:references] if options[:references]
      res = "FOREIGN KEY(#{quote_column_name(column)}) REFERENCES #{quote_table_name(to_table)}"
      res += "(#{options[:referenced_column]})" if options[:referenced_column]
      res
    end
  end
end