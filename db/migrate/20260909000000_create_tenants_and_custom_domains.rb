# frozen_string_literal: true

class CreateTenantsAndCustomDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.string :headline, null: false
      t.text :body, null: false
      t.timestamps
      t.index :slug, unique: true
    end

    create_table :custom_domains do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :hostname, null: false
      t.string :lifecycle, null: false, default: 'unconfirmed'
      t.integer :provider_id
      t.string :status, null: false, default: 'pending'
      t.text :status_message
      t.text :user_message
      t.boolean :is_resolving # rubocop:disable Rails/ThreeStateBooleanColumn -- provider field is nullable
      t.boolean :has_ssl # rubocop:disable Rails/ThreeStateBooleanColumn -- provider field is nullable
      t.string :dns_pointed_at
      t.timestamps
      t.index :hostname, unique: true
      t.index :provider_id, unique: true
    end

    add_check_constraint :custom_domains,
                         "lifecycle IN ('provisioning', 'active', 'unconfirmed', 'removal_pending', 'fixture')",
                         name: 'custom_domains_lifecycle'
  end
end
