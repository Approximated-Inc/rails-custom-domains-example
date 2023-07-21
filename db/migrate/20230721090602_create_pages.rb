# frozen_string_literal: true

class CreatePages < ActiveRecord::Migration[7.0]
  def change
    create_table :pages do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :domain, null: false

      t.timestamps

      t.index :domain, unique: true
    end
  end
end
