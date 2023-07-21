# frozen_string_literal: true

require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! ENV.fetch('APP_PRIMARY_DOMAIN')
  end

  def test_app_domain_routing
    get URI::HTTP.build(host: ENV.fetch('APP_PRIMARY_DOMAIN'), path: '/').to_s

    assert_equal 'pages', @controller.controller_name
    assert_equal 'index', @controller.action_name
    assert_response :success
  end

  def test_index
    get pages_root_url

    assert_response :success
  end

  def test_new
    get new_page_url

    assert_response :success
  end

  def test_create
    stub_apx_create_request(
      :success, body: {
        incoming_address: 'new-page.com',
        target_address: ENV.fetch('APP_PRIMARY_DOMAIN')
      }
    )

    new_attrs = { title: 'New Page', content: 'New page content', domain: 'new-page.com' }

    assert_difference('Page.count') do
      post pages_url, params: { page: new_attrs }
    end

    page = Page.order(:created_at).last

    assert_equal new_attrs[:title], page.title
    assert_equal new_attrs[:content], page.content
    assert_equal new_attrs[:domain], page.domain

    assert_redirected_to page_url(page)
  end

  def test_show
    get page_url(pages(:one))

    assert_response :success
  end

  def test_edit
    get edit_page_url(pages(:one))

    assert_response :success
  end

  def test_update
    page = pages(:one)

    stub_apx_read_request(:success, incoming_address: page.domain)

    stub_apx_update_request(
      :success, body: {
        current_incoming_address: page.domain,
        incoming_address: 'updated-domain.com'
      }
    )

    new_attrs = { title: 'Updated page', content: 'Updated content', domain: 'updated-domain.com' }
    patch page_url(page), params: { page: new_attrs }

    page.reload

    assert_equal new_attrs[:title], page.title
    assert_equal new_attrs[:content], page.content
    assert_equal new_attrs[:domain], page.domain

    assert_redirected_to page_url(page)
  end

  def test_destroy
    page = pages(:one)

    stub_apx_delete_request(:success, incoming_address: page.domain)

    assert_difference('Page.count', -1) do
      delete page_url(page)
    end

    assert_redirected_to pages_root_url
  end
end
