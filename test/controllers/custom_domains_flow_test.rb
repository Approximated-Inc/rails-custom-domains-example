# frozen_string_literal: true

require 'test_helper'

class CustomDomainsFlowTest < ActionDispatch::IntegrationTest
  setup { host! 'control.test' }

  test 'requires a tenant session for management' do
    get control_root_path

    assert_redirected_to new_session_path
  end

  test 'fixture login scopes the dashboard to its server-side tenant' do
    post session_path, params: { tenant_slug: 'atlas', password: 'demo-only' }
    follow_redirect!

    assert_response :success
    assert_includes response.body, 'Local demo mode'
    assert_includes response.body, 'atlas.test'
    assert_not_includes response.body, 'juniper.test'
  end

  test 'cannot operate on another tenant domain id' do
    post session_path, params: { tenant_slug: 'atlas', password: 'demo-only' }

    assert_no_changes -> { custom_domains(:juniper_fixture).reload.lifecycle } do
      delete custom_domain_path(custom_domains(:juniper_fixture))
    end
    assert_response :not_found
  end

  test 'local mock provisions and releases a tenant domain through the real controller flow' do
    post session_path, params: { tenant_slug: 'atlas', password: 'demo-only' }

    assert_difference -> { tenants(:atlas).custom_domains.count }, 1 do
      post custom_domains_path, params: { hostname: 'updates-atlas.com' }
    end
    assert_redirected_to control_root_path

    domain = tenants(:atlas).custom_domains.find_by!(hostname: 'updates-atlas.com')

    assert_equal 'active', domain.lifecycle
    assert_equal 'local mock', domain.status
    assert_predicate domain.provider_id, :positive?

    delete custom_domain_path(domain)

    assert_redirected_to control_root_path
    assert_equal 'removal_pending', domain.reload.lifecycle

    assert_difference -> { tenants(:atlas).custom_domains.count }, -1 do
      post refresh_custom_domain_path(domain)
    end
    assert_redirected_to control_root_path
  end

  test 'rails forgery protection rejects a browser mutation without a valid token' do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    post session_path,
         params: { tenant_slug: 'atlas', password: 'demo-only' },
         headers: { 'Origin' => 'http://evil.control.test' }

    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = original
  end
end
