# frozen_string_literal: true

class DomainLifecycle
  class Conflict < StandardError; end
  class ReconciliationRequired < StandardError; end

  def initialize(tenant:, client: Approximated.configured)
    @tenant = tenant
    @client = client
  end

  def add(input)
    hostname = DomainName.normalize(input)
    existing = CustomDomain.find_by(hostname:)
    raise Conflict, 'That hostname is already reserved.' if existing && existing.tenant_id != @tenant.id
    return existing if existing&.lifecycle == 'active' && existing.provider_id.present?
    raise ReconciliationRequired, 'This reservation needs operator reconciliation.' if existing

    reservation = @tenant.custom_domains.create!(hostname:, lifecycle: 'provisioning', status: 'creating')
    remote = @client.create(hostname)
    confirm_identity!(reservation, remote)
    apply_remote!(reservation, remote)
  rescue ActiveRecord::RecordNotUnique
    raise Conflict, 'That hostname is already reserved.'
  rescue StandardError
    # This must be a best-effort fail-closed write even if unrelated validations changed.
    # rubocop:disable-next Rails/SkipsModelValidations
    reservation&.update_columns(lifecycle: 'unconfirmed', provider_id: nil, status: 'error',
                                status_message: 'Provisioning outcome is unconfirmed.', updated_at: Time.current)
    raise
  end

  def refresh(id)
    domain = owned_domain(id)
    require_confirmed!(domain)
    provider_id = domain.provider_id
    remote = @client.get(provider_id)
    confirm_identity!(domain, remote)

    apply_refresh_if_current!(domain, remote)
  rescue ReconciliationRequired
    mark_unconfirmed_if_current!(domain)
    raise
  rescue Approximated::NotFound
    raise unless domain&.lifecycle == 'removal_pending'

    @tenant.custom_domains.where(id: domain.id, hostname: domain.hostname, provider_id:,
                                 lifecycle: 'removal_pending').delete_all
    nil
  end

  def remove(id)
    domain = owned_domain(id)
    require_confirmed!(domain)
    if domain.lifecycle == 'active'
      domain.update!(lifecycle: 'removal_pending', status: 'removal pending',
                     status_message: 'Waiting for provider deletion confirmation.', is_resolving: nil, apx_hit: nil,
                     has_ssl: nil)
    end
    @client.delete(domain.provider_id)
    nil
  end

  private

  def owned_domain(id)
    @tenant.custom_domains.find(id)
  end

  def require_confirmed!(domain)
    return if %w[active removal_pending].include?(domain.lifecycle) && domain.provider_id.present?

    raise ReconciliationRequired, 'Provider ownership is unconfirmed; an operator must reconcile this reservation.'
  end

  def confirm_identity!(domain, remote)
    id_matches = domain.provider_id.present? ? remote.id == domain.provider_id : remote.id.positive?
    return if id_matches && DomainName.normalize(remote.incoming_address) == domain.hostname

    raise ReconciliationRequired, 'Approximated returned a different virtual host.'
  end

  def apply_remote!(domain, remote)
    domain.update!(remote_attributes(remote).merge(provider_id: remote.id))
    domain
  end

  def apply_refresh_if_current!(domain, remote)
    attributes = remote_attributes(remote).merge(updated_at: Time.current)
    # Atomic identity/state predicate is required so a delayed response cannot update a replacement.
    # rubocop:disable-next Rails/SkipsModelValidations
    @tenant.custom_domains.where(id: domain.id, hostname: domain.hostname, provider_id: domain.provider_id,
                                 lifecycle: 'active').update_all(attributes)
    @tenant.custom_domains.find_by(id: domain.id, hostname: domain.hostname, provider_id: domain.provider_id)
  end

  def mark_unconfirmed_if_current!(domain)
    return if domain&.provider_id.blank?

    # Atomic identity/state predicate is required so removal wins a reconciliation race.
    # rubocop:disable-next Rails/SkipsModelValidations
    @tenant.custom_domains.where(id: domain.id, hostname: domain.hostname, provider_id: domain.provider_id,
                                 lifecycle: 'active').update_all(
                                   lifecycle: 'unconfirmed', status: 'error',
                                   status_message: 'Provider identity no longer matches this reservation.',
                                   is_resolving: nil, apx_hit: nil, has_ssl: nil, updated_at: Time.current
                                 )
  end

  def remote_attributes(remote)
    {
      lifecycle: 'active',
      status: remote.status,
      status_message: remote.status_message,
      user_message: remote.user_message,
      is_resolving: remote.is_resolving,
      apx_hit: remote.apx_hit,
      has_ssl: remote.has_ssl,
      dns_pointed_at: remote.dns_pointed_at
    }
  end
end
