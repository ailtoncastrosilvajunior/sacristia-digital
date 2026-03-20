# frozen_string_literal: true

# Usa a query do Rails 7 (generate_subscripts) em vez da do Rails 8.1 (array_position)
# Compatível com PostgreSQL 9.3+ - array_position só existe a partir do 9.5
module PostgreSQLInt2VectorCompat
  def primary_keys(table_name)
    query_values(<<~SQL, "SCHEMA")
      SELECT a.attname
      FROM (
        SELECT indrelid, indkey, generate_subscripts(indkey, 1) idx
        FROM pg_index
        WHERE indrelid = #{quote(quote_table_name(table_name))}::regclass
          AND indisprimary
      ) i
      JOIN pg_attribute a
        ON a.attrelid = i.indrelid
        AND a.attnum = i.indkey[i.idx]
      ORDER BY i.idx
    SQL
  end
end

# Carrega o adapter PostgreSQL completo (define o módulo PostgreSQL)
require "active_record/connection_adapters/postgresql_adapter"

# Aplica o patch diretamente no adapter (prepend no SchemaStatements pode não
# ser respeitado em alguns contextos, ex: schema_cache)
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PostgreSQLInt2VectorCompat)
