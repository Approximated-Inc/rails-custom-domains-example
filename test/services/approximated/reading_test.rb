# frozen_string_literal: true

require 'test_helper'

class Approximated
  class ReadingTest < ActiveSupport::TestCase
    def setup
      @apx = Approximated.new
      @incoming_address = 'incoming.com'
    end

    def test_success
      api_response = stub_apx_read_request(:success, incoming_address: @incoming_address)
      apx_result = read_apx_vhost

      assert_equal 200, apx_result.status
      assert_equal api_response, apx_result.body
    end

    def test_unauthorized
      stub_apx_read_request(:unauthorized, incoming_address: @incoming_address)
      assert_raises(Approximated::UnauthorizedError) { read_apx_vhost }
    end

    def test_not_found
      stub_apx_read_request(:not_found, incoming_address: @incoming_address)
      assert_raises(Approximated::ResourceNotFound) { read_apx_vhost }
    end

    private

    def read_apx_vhost
      @apx.get_vhost(@incoming_address)
    end
  end
end
