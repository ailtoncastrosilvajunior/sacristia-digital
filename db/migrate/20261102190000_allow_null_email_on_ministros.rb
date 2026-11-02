# frozen_string_literal: true

class AllowNullEmailOnMinistros < ActiveRecord::Migration[8.0]
  def up
    remove_index :ministros, :email, if_exists: true
    change_column_null :ministros, :email, true
    execute "UPDATE ministros SET email = NULL WHERE email = ''"
    add_index :ministros, :email, unique: true, where: "email IS NOT NULL", name: "index_ministros_on_email_unique"
  end

  def down
    remove_index :ministros, name: "index_ministros_on_email_unique", if_exists: true
    execute "UPDATE ministros SET email = '' WHERE email IS NULL"
    change_column_null :ministros, :email, false
    add_index :ministros, :email, unique: true
  end
end
