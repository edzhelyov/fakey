require 'connection_adapters/abstract/schema_definitions'

module ActiveRecord
  module ConnectionAdapters    
    # Table.class_eval{include Fkey::Table}
    TableDefinition.class_eval{include Fkey::TableDefinition}
  end
end

if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  require 'connection_adapters/postgresql_adapter'
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval{include Fkey::PostgreSQLAdapter}
else
  raise "Only PostgreSQL is currently supported by the fkey plugin."
end
