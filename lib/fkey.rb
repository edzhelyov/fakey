require 'connection_adapters/abstract/schema_definitions'

module ActiveRecord
  module ConnectionAdapters    
    TableDefinition.class_eval{include Fkey::TableDefinition}
  end
end

if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  require 'connection_adapters/postgresql_adapter'
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval{include Fkey::PostgreSQLAdapter}
elsif defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
  require 'connection_adapters/mysql_adapter'
  ActiveRecord::ConnectionAdapters::MysqlAdapter.class_eval{include Fkey::MysqlAdapter}
else
  raise "Only PostgreSQL and MySQL are currently supported by the fakey plugin."
end
