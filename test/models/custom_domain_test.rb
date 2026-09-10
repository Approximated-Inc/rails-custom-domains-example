# frozen_string_literal: true

require 'test_helper'

class CustomDomainTest < ActiveSupport::TestCase
  test 'normalizes case, a trailing dot, and internationalized names' do
    domain = tenants(:atlas).custom_domains.new(hostname: ' BÜCHER.Example. ')
    domain.valid?

    assert_equal 'xn--bcher-kva.example', domain.hostname
  end

  test 'rejects URLs, ports, wildcards, IPs, localhost, and the control host' do
    ['https://example.com', 'example.com:443', '*.example.com', '127.0.0.1', 'localhost',
     'control.test'].each do |value|
      domain = tenants(:atlas).custom_domains.new(hostname: value)

      assert_not domain.valid?, "expected #{value.inspect} to be rejected"
    end
  end

  test 'enforces one reservation globally' do
    duplicate = tenants(:juniper).custom_domains.new(hostname: 'ATLAS.TEST.')

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:hostname], :present?
  end

  test 'request parsing accepts a configured single-label control host only when explicit' do
    previous = ENV.fetch('CONTROL_HOST', nil)
    ENV['CONTROL_HOST'] = 'localhost'

    assert_equal 'localhost', DomainName.normalize('LOCALHOST.', allow_control: true)
    assert_raises(DomainName::Invalid) { DomainName.normalize('localhost') }
  ensure
    ENV['CONTROL_HOST'] = previous
  end

  test 'routes only ready confirmed domains and explicit local fixtures' do
    unconfirmed = tenants(:atlas).custom_domains.create!(hostname: 'pending.example.com', lifecycle: 'unconfirmed',
                                                         status: 'error')
    diagnostic_only = tenants(:atlas).custom_domains.create!(hostname: 'diagnostic.example.com', lifecycle: 'active',
                                                             provider_id: 41, is_resolving: true, apx_hit: false,
                                                             has_ssl: true)
    ready = tenants(:atlas).custom_domains.create!(hostname: 'ready.example.com', lifecycle: 'active', provider_id: 42,
                                                   is_resolving: false, apx_hit: true, has_ssl: true)

    assert_nil CustomDomain.routable.find_by(hostname: unconfirmed.hostname)
    assert_nil CustomDomain.routable.find_by(hostname: diagnostic_only.hostname)
    assert_equal ready, CustomDomain.routable.find_by(hostname: ready.hostname)
    assert_equal custom_domains(:atlas_fixture), CustomDomain.routable.find_by(hostname: 'atlas.test')
  end
end
