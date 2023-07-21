# frozen_string_literal: true

require 'test_helper'

class PublicPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @page = pages(:one)
    host! @page.domain
  end

  def test_page_domain_routing_via_host
    get URI::HTTP.build(host: @page.domain, path: '/').to_s

    assert_equal 'public_pages', @controller.controller_name
    assert_equal 'show', @controller.action_name
    assert_response :success
  end

  def test_page_domain_routing_via_header
    url = URI::HTTP.build(host: ENV.fetch('APP_PRIMARY_DOMAIN'), path: '/').to_s
    get url, headers: { 'apx-incoming-host' => @page.domain }

    assert_equal 'public_pages', @controller.controller_name
    assert_equal 'show', @controller.action_name
    assert_response :success
  end

  def test_show
    get public_pages_root_path

    assert_response :success
  end
end
