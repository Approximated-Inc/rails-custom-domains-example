# frozen_string_literal: true

class CustomDomain < ApplicationRecord
  LIFECYCLES = %w[provisioning active unconfirmed removal_pending fixture].freeze
  belongs_to :tenant

  before_validation :normalize_hostname

  validates :hostname, presence: true, uniqueness: true
  validates :lifecycle, inclusion: { in: LIFECYCLES }
  validates :provider_id, uniqueness: true, allow_nil: true
  validate :hostname_has_public_suffix

  scope :routable, lambda {
    where(lifecycle: 'fixture').or(
      where(lifecycle: 'active', apx_hit: true, has_ssl: true).where.not(provider_id: nil)
    )
  }

  private

  def normalize_hostname
    self.hostname = DomainName.normalize(hostname)
  rescue DomainName::Invalid => e
    errors.add(:hostname, e.message)
  end

  def hostname_has_public_suffix
    return if hostname.blank? || lifecycle == 'fixture'
    return if PublicSuffix.valid?(hostname, default_rule: nil)

    errors.add(:hostname, 'must use a recognized public suffix')
  end
end
