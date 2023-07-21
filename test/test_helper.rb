# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'webmock/minitest'

require 'support/approximated_helpers'

module ActiveSupport
  class TestCase
    include TestSupport::ApproximatedHelpers

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Disable external requests by default
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end
