# frozen_string_literal: true

require 'test_helper'

class Approximated
  class CreatingTest < ActiveSupport::TestCase
    def setup
      @apx = Approximated.new

      @request_data = {
        incoming_address: 'incoming.com',
        target_address: 'target.com',
        exact_match: false
      }
    end

    def test_success
      api_response = stub_apx_create_request(:success, body: @request_data)
      apx_result = create_apx_vhost

      assert_equal 201, apx_result.status
      assert_equal api_response, apx_result.body
    end

    def test_unauthorized
      stub_apx_create_request(:unauthorized, body: @request_data)
      assert_raises(Approximated::UnauthorizedError) { create_apx_vhost }
    end

    private

    def create_apx_vhost
      @apx.create_vhost(
        @request_data[:incoming_address],
        @request_data[:target_address],
        exact_match: @request_data[:exact_match]
      )
    end
  end
end
