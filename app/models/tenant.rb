# frozen_string_literal: true

class Tenant < ApplicationRecord
  has_many :custom_domains, dependent: :destroy

  validates :slug, :name, :headline, :body, presence: true
  validates :slug, uniqueness: true
end
