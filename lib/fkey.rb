require 'connection_adapters/abstract/schema_definitions'

module Fakey
  class << self
    def load
      ActiveRecord::ConnectionAdapters::TableDefinition.class_eval do
        include Fkey::TableDefinition
      end
      ActiveRecord::ConnectionAdapters::Table.class_eval do
        include Fkey::Table
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
    end
  end
end

ActiveSupport.on_load :active_record do
  Fakey.load
end
