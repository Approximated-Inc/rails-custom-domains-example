# frozen_string_literal: true

require 'test_helper'

class PublicRoutingTest < ActionDispatch::IntegrationTest
  test 'routes two fixture hosts to different tenant content' do
    host! 'atlas.test'
    get '/'

    assert_response :success
    assert_includes response.body, 'Atlas Press'

    host! 'juniper.test'
    get '/'

    assert_response :success
    assert_includes response.body, 'Juniper Journal'
  end

  test 'returns 404 for an unknown or unroutable host' do
    host! 'unknown.test'
    get '/'

    assert_response :not_found

    domain = tenants(:atlas).custom_domains.create!(hostname: 'unconfirmed.example.com', lifecycle: 'unconfirmed',
                                                    status: 'error')
    host! domain.hostname
    get '/'

    assert_response :not_found

    waiting_for_tls = tenants(:atlas).custom_domains.create!(hostname: 'waiting.example.com', lifecycle: 'active',
                                                             provider_id: 99, is_resolving: true, apx_hit: true,
                                                             has_ssl: false)
    host! waiting_for_tls.hostname
    get '/'

    assert_response :not_found
  end

  test 'does not trust a client supplied incoming-host header' do
    host! 'unknown.test'
    get '/', headers: { 'apx-incoming-host' => 'atlas.test' }

    assert_response :not_found
  end
end
