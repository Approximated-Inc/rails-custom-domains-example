# frozen_string_literal: true

require 'test_helper'

class Approximated
  class DeletingTest < ActiveSupport::TestCase
    def setup
      @apx = Approximated.new
      @incoming_address = 'incoming.com'
    end

    def test_success
      stub_apx_delete_request(:success, incoming_address: @incoming_address)
      apx_result = delete_apx_vhost

      assert_equal 200, apx_result.status
      assert_nil apx_result.body
    end

    def test_unauthorized
      stub_apx_delete_request(:unauthorized, incoming_address: @incoming_address)
      assert_raises(Approximated::UnauthorizedError) { delete_apx_vhost }
    end

    def test_not_found
      stub_apx_delete_request(:not_found, incoming_address: @incoming_address)
      assert_raises(Approximated::ResourceNotFound) { delete_apx_vhost }
    end

    private

    def delete_apx_vhost
      @apx.delete_vhost(@incoming_address)
    end
  end
end
