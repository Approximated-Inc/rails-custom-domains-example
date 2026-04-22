# frozen_string_literal: true

require 'application_system_test_case'

class PagesTest < ApplicationSystemTestCase
  setup do
    page.driver.add_headers('apx-incoming-host' => ENV.fetch('APP_PRIMARY_DOMAIN'))
  end

  def test_index
    visit pages_root_url

    assert_selector 'h1', text: 'Pages'
  end

  def test_show
    visit pages_root_url
    click_on pages(:one).title

    assert_selector 'h1', text: pages(:one).title
  end

  def test_create
    stub_apx_create_request(
      :success, body: {
        incoming_address: 'my-new-page.com',
        target_address: ENV.fetch('APP_PRIMARY_DOMAIN')
      }
    )

    visit pages_root_url
    click_on 'New page'

    fill_in 'Title', with: 'My New Page'
    fill_in 'Content', with: 'My new page content'
    fill_in 'Domain', with: 'my-new-page.com'

    click_on 'Create page'

    assert_text <<~MESSAGE.squish
      In order to connect your domain, you'll need to have a DNS A record that points acustomdomain.com
      at 213.188.210.168. If you already have an A record for that address, please change it to point
      at 213.188.210.168 and remove any other A records for that exact address. It may take a few minutes
      for your SSL certificate to take effect once you've pointed your DNS A record.
    MESSAGE

    assert_selector 'h1', text: 'My New Page'
  end

  def test_update
    stub_apx_read_request(:success, incoming_address: pages(:one).domain)

    stub_apx_update_request(
      :success, body: {
        current_incoming_address: pages(:one).domain,
        incoming_address: 'my-updated-page.com'
      }
    )

    visit page_url(pages(:one))
    click_on 'Edit this page'

    fill_in 'Title', with: 'My Updated Page'
    fill_in 'Content', with: 'My updated page content'
    fill_in 'Domain', with: 'my-updated-page.com'

    click_on 'Save page'

    assert_text 'Page was successfully updated.'
    assert_selector 'h1', text: 'My Updated Page'
  end

  def test_destroy
    stub_apx_delete_request(:success, incoming_address: pages(:one).domain)

    visit page_url(pages(:one))

    accept_confirm do
      click_on 'Destroy this page'
    end

    assert_text 'Page was successfully destroyed.'
    assert_selector 'h1', text: 'Pages'
  end
end
