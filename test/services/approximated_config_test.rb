# frozen_string_literal: true

require 'test_helper'

class ApproximatedConfigTest < ActiveSupport::TestCase
  test 'missing API key selects the local mock' do
    client = Approximated.configured(env: { 'APP_ORIGIN_HOST' => 'origin.test' })

    assert_instance_of Approximated::Mock, client
    assert_equal :mock, Approximated.mode(env: {})
  end

  test 'blank API key selects the local mock' do
    env = { 'APPROXIMATED_API_KEY' => '   ', 'APP_ORIGIN_HOST' => 'origin.test' }

    assert_instance_of Approximated::Mock, Approximated.configured(env:)
    assert_equal :mock, Approximated.mode(env:)
  end

  test 'nonempty API key selects the fixed Approximated cloud API' do
    env = {
      'APPROXIMATED_API_KEY' => 'dummy-key',
      'APP_ORIGIN_HOST' => 'origin.test',
      'APPROXIMATED_API_URL' => 'https://wrong.example.invalid'
    }

    client = Approximated.configured(env:)

    assert_instance_of Approximated, client
    assert_equal Approximated::CLOUD_API_URL, client.base_url
    assert_equal :real, Approximated.mode(env:)
  end

  test 'explicit mock mode wins even when a key is present' do
    env = {
      'APPROXIMATED_MODE' => 'mock',
      'APPROXIMATED_API_KEY' => 'dummy-key',
      'APP_ORIGIN_HOST' => 'origin.test'
    }

    assert_instance_of Approximated::Mock, Approximated.configured(env:)
    assert_equal :mock, Approximated.mode(env:)
  end

  test 'local mock returns visibly simulated status without network access' do
    client = Approximated::Mock.new

    created = client.create('docs.example.com')

    assert_predicate created.id, :positive?
    assert_equal 'docs.example.com', created.incoming_address
    assert_equal 'local mock', created.status
    assert_match(/simulated/i, created.user_message)
    assert_equal created, client.get(created.id)
    assert_nil client.delete(created.id)
    assert_raises(Approximated::NotFound) { client.get(created.id) }
  end

  test 'explicit real mode rejects a blank key' do
    error = assert_raises(Approximated::ApiError) do
      Approximated.configured(env: { 'APPROXIMATED_MODE' => 'real', 'APPROXIMATED_API_KEY' => ' ' })
    end

    assert_match(/API key/i, error.message)
  end
end
