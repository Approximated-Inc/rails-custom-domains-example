# frozen_string_literal: true

require 'test_helper'

class PageTest < ActiveSupport::TestCase
  def setup
    @page = Page.new(title: 'Page', content: 'Content', domain: 'custom-domain.com')
  end

  def test_valid
    assert_predicate @page, :valid?
  end

  def test_invalid_without_title
    @page.title = nil

    assert_invalid_attr @page, :title
  end

  def test_invalid_without_content
    @page.content = nil

    assert_invalid_attr @page, :content
  end

  def test_invalid_without_domain
    @page.domain = nil

    assert_invalid_attr @page, :domain
  end

  def test_valid_with_subdomain
    @page.domain = 'custom.domain.com'

    assert_predicate @page, :valid?
  end

  def test_invalid_with_custom_tld
    @page.domain = 'domain.tldnotlisted'

    assert_invalid_attr @page, :domain
  end

  def test_invalid_without_sld
    @page.domain = 'com'

    assert_invalid_attr @page, :domain
  end

  def test_invalid_with_restricted_domain
    @page.domain = ENV.fetch('APP_PRIMARY_DOMAIN')

    assert_invalid_attr @page, :domain
  end

  def test_invalid_without_unique_domain
    @page.domain = pages(:one).domain

    assert_invalid_attr @page, :domain
  end

  def test_create_apx_vhost
    body = {
      incoming_address: @page.domain,
      target_address: ENV.fetch('APP_PRIMARY_DOMAIN')
    }

    stub_apx_create_request(:unauthorized, body:)

    assert_not @page.save

    stub_apx_create_request(:success, body:)

    assert @page.save
  end

  def test_update_existing_apx_vhost
    page = pages(:one)

    stub_apx_read_request(:success, incoming_address: page.domain)

    body = {
      current_incoming_address: page.domain,
      incoming_address: 'updated-domain.com'
    }

    stub_apx_update_request(:unauthorized, body:)

    assert_not page.update(domain: 'updated-domain.com')

    stub_apx_update_request(:success, body:)

    assert page.update(domain: 'updated-domain.com')
  end

  def test_update_missing_apx_vhost
    page = pages(:one)

    stub_apx_read_request(:unauthorized, incoming_address: page.domain)

    assert_not page.update(domain: 'updated-domain.com')

    stub_apx_read_request(:not_found, incoming_address: page.domain)

    stub_apx_create_request(
      :success, body: {
        incoming_address: 'updated-domain.com',
        target_address: ENV.fetch('APP_PRIMARY_DOMAIN')
      }
    )

    assert page.update(domain: 'updated-domain.com')
  end

  def test_delete_apx_vhost
    page = pages(:one)

    stub_apx_delete_request(:unauthorized, incoming_address: page.domain)

    assert_not page.destroy

    stub_apx_delete_request(:success, incoming_address: page.domain)

    assert page.destroy
  end

  private

  def assert_invalid_attr(page, attr_name)
    assert_not_predicate page, :valid?
    assert_predicate page.errors[attr_name], :present?
  end
end
