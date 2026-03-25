# frozen_string_literal: true

class ChangeUsersToPerfisArray < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :perfis, :string, array: true, default: [], null: false
    add_reference :users, :sacerdote, foreign_key: true, index: true

    execute <<-SQL.squish
      UPDATE users
      SET perfis = CASE
        WHEN perfil IS NOT NULL AND perfil != '' THEN ARRAY[perfil]::varchar[]
        ELSE ARRAY['ministro']::varchar[]
      END
    SQL

    remove_index :users, :perfil, if_exists: true
    remove_column :users, :perfil
    add_index :users, :perfis, using: "gin"
  end

  def down
    remove_index :users, :perfis
    add_column :users, :perfil, :string, default: "ministro", null: false

    execute <<-SQL.squish
      UPDATE users SET perfil = COALESCE(perfis[1], 'ministro')
    SQL

    remove_reference :users, :sacerdote, foreign_key: true
    remove_column :users, :perfis
    add_index :users, :perfil
  end
end
