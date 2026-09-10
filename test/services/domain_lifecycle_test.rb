# frozen_string_literal: true

require 'test_helper'

class DomainLifecycleTest < ActiveSupport::TestCase
  FakeRemote = Data.define(:id, :incoming_address, :status, :status_message, :user_message, :is_resolving, :apx_hit,
                           :has_ssl, :dns_pointed_at)

  DelayedStatusRemote = Struct.new(*FakeRemote.members, keyword_init: true) do
    attr_accessor :before_status

    def status
      before_status&.call
      self[:status]
    end
  end

  class FakeApproximated
    attr_accessor :create_error, :delete_error, :get_error, :on_get, :remote, :preserve_create_hostname
    attr_reader :create_calls, :get_calls, :delete_calls

    def initialize
      @create_calls = []
      @get_calls = []
      @delete_calls = []
      @remote = FakeRemote.new(id: 901, incoming_address: 'alpha.example.com', status: 'pending',
                               status_message: 'Waiting', user_message: 'Add the supplied DNS record.',
                               is_resolving: nil, apx_hit: nil, has_ssl: nil, dns_pointed_at: nil)
    end

    def create(hostname)
      @create_calls << hostname
      raise create_error if create_error

      preserve_create_hostname ? remote : remote.with(incoming_address: hostname)
    end

    def get(id)
      @get_calls << id
      on_get&.call
      raise get_error if get_error

      remote
    end

    def delete(id)
      @delete_calls << id
      raise delete_error if delete_error
    end
  end

  setup do
    @tenant = tenants(:atlas)
    @api = FakeApproximated.new
    @service = DomainLifecycle.new(tenant: @tenant, client: @api)
  end

  test 'reserves then confirms the provider identity and keeps readiness nullable' do
    domain = @service.add(' Alpha.Example.COM. ')

    assert_equal 'alpha.example.com', domain.hostname
    assert_equal 901, domain.provider_id
    assert_equal 'active', domain.lifecycle
    assert_nil domain.is_resolving
    assert_nil domain.apx_hit
    assert_nil domain.has_ssl
    assert_equal ['alpha.example.com'], @api.create_calls
  end

  test 'keeps an unconfirmed owner reservation after an ambiguous create' do
    @api.create_error = Approximated::ApiError.new('conflict or timeout')

    assert_raises(Approximated::ApiError) { @service.add('ambiguous.example.com') }
    domain = CustomDomain.find_by!(hostname: 'ambiguous.example.com')

    assert_equal @tenant, domain.tenant
    assert_equal 'unconfirmed', domain.lifecycle
    assert_nil domain.provider_id
    assert_raises(DomainLifecycle::ReconciliationRequired) { @service.refresh(domain.id) }
    assert_raises(DomainLifecycle::ReconciliationRequired) { @service.remove(domain.id) }
    assert_empty @api.get_calls
    assert_empty @api.delete_calls
  end

  test 'rejects a mismatched provider identity' do
    @api.remote = @api.remote.with(incoming_address: 'someone-elses.example.com')
    @api.preserve_create_hostname = true

    assert_raises(DomainLifecycle::ReconciliationRequired) { @service.add('ours.example.com') }
    domain = CustomDomain.find_by!(hostname: 'ours.example.com')

    assert_equal 'unconfirmed', domain.lifecycle
    assert_nil domain.provider_id
  end

  test 'does not let a stale refresh reactivate removal pending' do
    domain = @service.add('alpha.example.com')
    @api.on_get = -> { domain.update!(lifecycle: 'removal_pending') }

    assert_equal 'removal_pending', @service.refresh(domain.id).lifecycle
  end

  test 'does not adopt a different provider id returned for the stored id' do
    domain = @service.add('alpha.example.com')
    @api.remote = @api.remote.with(id: 902)

    assert_raises(DomainLifecycle::ReconciliationRequired) { @service.refresh(domain.id) }
    assert_equal 'unconfirmed', domain.reload.lifecycle
    assert_equal 901, domain.provider_id
    assert_equal [901], @api.get_calls
  end

  test 'does not let a delayed refresh update reactivate removal pending' do
    domain = @service.add('alpha.example.com')
    remote = DelayedStatusRemote.new(**@api.remote.to_h)
    remote.before_status = -> { domain.update!(lifecycle: 'removal_pending') }
    @api.remote = remote

    assert_equal 'removal_pending', @service.refresh(domain.id).lifecycle
    assert_equal 901, domain.reload.provider_id
  end

  test 'does not let mismatch reconciliation overwrite removal pending' do
    domain = @service.add('alpha.example.com')
    @api.remote = @api.remote.with(id: 902)
    @api.on_get = -> { domain.update!(lifecycle: 'removal_pending') }

    assert_raises(DomainLifecycle::ReconciliationRequired) { @service.refresh(domain.id) }
    assert_equal 'removal_pending', domain.reload.lifecycle
    assert_equal 901, domain.provider_id
  end

  test 'disables an active mapping when refresh returns a different hostname' do
    domain = @service.add('alpha.example.com')
    domain.update!(apx_hit: true, has_ssl: true)
    @api.remote = @api.remote.with(incoming_address: 'recycled.example.com')

    assert_raises(DomainLifecycle::ReconciliationRequired) { @service.refresh(domain.id) }
    assert_equal 'unconfirmed', domain.reload.lifecycle
    assert_nil domain.apx_hit
    assert_nil domain.has_ssl
    assert_empty @api.delete_calls
  end

  test 'retains failed deletion and retries the same confirmed provider id' do
    domain = @service.add('alpha.example.com')
    @api.delete_error = Approximated::ApiError.new('unavailable')

    assert_raises(Approximated::ApiError) { @service.remove(domain.id) }
    assert_equal 'removal_pending', domain.reload.lifecycle
    assert_equal [901], @api.delete_calls

    @api.delete_error = nil
    @service.remove(domain.id)

    assert_equal [901, 901], @api.delete_calls
  end

  test 'releases only the same pending reservation after get by id returns 404' do
    domain = @service.add('alpha.example.com')
    @service.remove(domain.id)
    @api.get_error = Approximated::NotFound.new('gone')

    assert_nil @service.refresh(domain.id)
    assert_equal [901], @api.get_calls
    assert_not CustomDomain.exists?(domain.id)
  end

  test 'does not delete a replacement row created during delayed 404 confirmation' do
    domain = @service.add('alpha.example.com')
    @service.remove(domain.id)
    replacement = nil
    @api.get_error = Approximated::NotFound.new('gone')
    @api.on_get = lambda do
      domain.delete
      replacement = tenants(:juniper).custom_domains.create!(hostname: 'replacement.example.com',
                                                             lifecycle: 'unconfirmed', status: 'reserved')
    end

    assert_nil @service.refresh(domain.id)
    assert_predicate replacement, :persisted?
    assert CustomDomain.exists?(replacement.id)
  end
end
