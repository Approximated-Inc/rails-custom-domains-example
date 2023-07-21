# frozen_string_literal: true

class Page < ApplicationRecord
  attribute :user_message, :text

  validates :title, presence: true
  validates :content, presence: true
  validates :domain, presence: true, uniqueness: true, custom_domain: true

  after_create :create_apx_vhost
  after_update :update_apx_vhost
  after_destroy :destroy_apx_vhost

  private

  def create_apx_vhost
    apx = Approximated.new
    rollback_on_apx_error do
      result = apx.create_vhost(domain, ENV.fetch('APP_PRIMARY_DOMAIN'))
      self.user_message = result.body.dig('data', 'user_message').presence
    end
  end

  def update_apx_vhost
    return unless domain_previously_changed?

    apx = Approximated.new
    rollback_on_apx_error do
      apx.get_vhost(domain_previously_was)
      apx.update_vhost(domain_previously_was, 'incoming_address' => domain)
    rescue Approximated::ResourceNotFound
      apx.create_vhost(domain, ENV.fetch('APP_PRIMARY_DOMAIN'))
    end
  end

  def destroy_apx_vhost
    apx = Approximated.new
    rollback_on_apx_error do
      apx.delete_vhost(domain)
    rescue Approximated::ResourceNotFound
      # Ignore missing vhost
    end
  end

  def rollback_on_apx_error
    yield
  rescue Approximated::Error => e
    errors.add(:base, "APX Error: #{e.cause.to_s.upcase_first}")
    raise ActiveRecord::Rollback
  end
end
