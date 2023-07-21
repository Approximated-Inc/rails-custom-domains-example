# frozen_string_literal: true

require 'test_helper'

class Approximated
  class UpdatingTest < ActiveSupport::TestCase
    def setup
      @apx = Approximated.new

      @request_data = {
        current_incoming_address: 'incoming.com',
        incoming_address: 'new-incoming.com',
        exact_match: true
      }
    end

    def test_success
      api_response = stub_apx_update_request(:success, body: @request_data)
      apx_result = update_apx_vhost

      assert_equal 200, apx_result.status
      assert_equal api_response, apx_result.body
    end

    def test_unauthorized
      stub_apx_update_request(:unauthorized, body: @request_data)
      assert_raises(Approximated::UnauthorizedError) { update_apx_vhost }
    end

    def test_not_found
      stub_apx_update_request(:not_found, body: @request_data)
      assert_raises(Approximated::ResourceNotFound) { update_apx_vhost }
    end

    private

    def update_apx_vhost
      @apx.update_vhost(
        @request_data[:current_incoming_address],
        incoming_address: @request_data[:incoming_address],
        exact_match: @request_data[:exact_match]
      )
    end
  end
end
