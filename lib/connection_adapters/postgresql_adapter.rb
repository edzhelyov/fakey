module Fkey #:nodoc:
  module PostgreSQLAdapter 
    def add_foreign_key(to_table, column, options={})
      res = "FOREIGN KEY(#{quote_column_name(column)}) REFERENCES #{quote_table_name(to_table)}"
      res += "(#{options[:references]})" if options[:references]
      res
    end
  end
end