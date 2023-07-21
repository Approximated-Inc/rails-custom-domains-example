# frozen_string_literal: true

require 'application_system_test_case'

class PublicPagesTest < ApplicationSystemTestCase
  setup do
    @page = pages(:one)
    page.driver.add_headers('apx-incoming-host' => @page.domain)
  end

  def test_show
    visit public_pages_root_url

    assert_selector 'h1', text: @page.title
  end
end
