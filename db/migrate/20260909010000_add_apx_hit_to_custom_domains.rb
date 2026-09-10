# frozen_string_literal: true

class AddApxHitToCustomDomains < ActiveRecord::Migration[8.1]
  def change
    # Readiness is unknown until the provider reports it.
    add_column :custom_domains, :apx_hit, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
  end
end
