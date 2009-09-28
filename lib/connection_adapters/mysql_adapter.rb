module Fkey #:nodoc:
  module MysqlAdapter 
    def add_foreign_key(to_table, column, options={})
      to_table = options[:references] if options[:references]
      referenced_column = options[:referenced_column] || primary_key(to_table)
      "FOREIGN KEY(#{quote_column_name(column)}) REFERENCES #{quote_table_name(to_table)} (#{referenced_column})"
    end
  end
end