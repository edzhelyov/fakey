require "#{File.dirname(__FILE__)}/test_helper"

class FakeyTest < ActiveSupport::TestCase
  def inspect_foreign_keys(table)
    connection = ActiveRecord::Base.connection
    if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      connection.select_all <<-END_SQL
    SELECT t1.table_name,
           KCU.column_name, 
           KCU2.table_name as referenced_table_name, 
           KCU2.column_name as referenced_column_name
      FROM (SELECT constraint_name, table_catalog, table_schema, table_name, constraint_type 
              FROM information_schema.table_constraints 
             WHERE table_name='#{table}') AS t1 
INNER JOIN information_schema.key_column_usage        AS KCU  ON (t1.constraint_name=KCU.constraint_name) 
 LEFT JOIN information_schema.referential_constraints AS REF2 ON (REF2.constraint_name=t1.constraint_name) 
 LEFT JOIN information_schema.key_column_usage        AS KCU2 ON (REF2.unique_constraint_name=KCU2.constraint_name)
     WHERE t1.constraint_type = 'FOREIGN KEY'
  ORDER BY table_name, 
           column_name
END_SQL
    elsif defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
      connection.select_all <<-END_SQL
    SELECT kcu.table_name,
           kcu.column_name, 
           kcu.referenced_table_name,
           kcu.referenced_column_name
      FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu USING(constraint_name)
     WHERE tc.constraint_type = 'FOREIGN KEY'
  ORDER BY table_name, 
           column_name
END_SQL
    end
  end
  
  def teardown
    self.class.const_get(@method_name.match(/test_(.+)/)[1].camelize + "Migration").down
  end

  class BelongsToMigration < ActiveRecord::Migration
    def self.up
      create_table(:authors) {}
      create_table :books do |t|
        t.belongs_to :author
      end
    end
    
    def self.down
      drop_table :books
      drop_table :authors
    end
  end  

  def test_belongs_to
    BelongsToMigration.up
    assert_equal( {'table_name' => 'books', 'column_name' => 'author_id', 'referenced_table_name' => 'authors', 'referenced_column_name' => 'id'},
                   inspect_foreign_keys(:books).first)
  end
  
  class ReferencesMigration < ActiveRecord::Migration
    def self.up
      create_table(:authors) {}
      create_table :articles do |t|
        t.references :author
      end
    end
    
    def self.down
      drop_table :articles
      drop_table :authors
    end
  end

  def test_references
    ReferencesMigration.up
    assert_equal( {'table_name' => 'articles', 'column_name' => 'author_id', 'referenced_table_name' => 'authors', 'referenced_column_name' => 'id'},
                  inspect_foreign_keys(:articles).first)
  end
  
  class ExplicitColumnNameMigration < ActiveRecord::Migration
    def self.up
      create_table(:poets) {}
      create_table :poems do |t|
        t.belongs_to :author, :column => :author, :references => :poets
      end
    end

    def self.down
      drop_table :poems
      drop_table :poets
    end
  end
  
  def test_explicit_column_name
    ExplicitColumnNameMigration.up
    assert_equal( {'table_name' => 'poems', 'column_name' => 'author', 'referenced_table_name' => 'poets', 'referenced_column_name' => 'id'},
                  inspect_foreign_keys(:poems).first)
  end
  
  class MoreThanOneForeignKeyMigration < ActiveRecord::Migration
    def self.up
      create_table(:authors) {}
      create_table(:editors) {}
      create_table :scientific_articles do |t|
        t.belongs_to :author
        t.belongs_to :editor
      end
    end

    def self.down
      drop_table :scientific_articles
      drop_table :editors
      drop_table :authors
    end
  end
  
  def test_more_than_one_foreign_key
    MoreThanOneForeignKeyMigration.up
    assert_equal [{'table_name' => 'scientific_articles', 'column_name' => 'author_id', 'referenced_table_name' => 'authors', 'referenced_column_name' => 'id'},
                  {'table_name' => 'scientific_articles', 'column_name' => 'editor_id', 'referenced_table_name' => 'editors', 'referenced_column_name' => 'id'}],
                 inspect_foreign_keys(:scientific_articles)
  end
  
  class StringForeignKeyMigration < ActiveRecord::Migration
    class Author < ActiveRecord::Base; end
    def self.up
      execute "CREATE TABLE authors( name VARCHAR(255) PRIMARY KEY)"
      create_table :books do |t|
        t.belongs_to :author, :column => :author_name, :type => :string
      end
    end
  end 
  
  def test_string_foreign_key
    StringForeignKeyMigration.up
    assert_equal :string, StringForeignKeyMigration::Author.columns.detect{|c| c.name =='name'}.type
    assert_equal({'table_name' => 'books', 'column_name' => 'author_name', 'referenced_table_name' => 'authors', 'referenced_column_name' => 'name'},
                 inspect_foreign_keys(:books).first)
  
  end
  
  class ReferenceToNonPrimaryKeyMigration < ActiveRecord::Migration
    def self.up
      create_table :authors do |t|
        t.integer :ssid
      end
      execute("ALTER TABLE authors ADD UNIQUE(ssid)")
      create_table :books do |t|
        t.belongs_to :author_ssid, :column => :author_ssid, :references => :authors, :referenced_column => :ssid
      end
    end
    
    def self.down
      drop_table :books
      drop_table :authors
    end
  end
  
  def test_reference_to_non_primary_key
    ReferenceToNonPrimaryKeyMigration.up
    assert_equal({'table_name' => 'books', 'column_name' => 'author_ssid', 'referenced_table_name' => 'authors', 'referenced_column_name' => 'ssid'},
                 inspect_foreign_keys(:books).first)
  end
end
