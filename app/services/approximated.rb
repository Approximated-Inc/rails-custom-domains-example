# frozen_string_literal: true

# Approximated is a ruby wrapper for the Approximated API (https://approximated.app).
#
class Approximated
  # Data class holding a successful API response.
  Result = Data.define(:status, :body)

  # Approximated error base class.
  class Error < StandardError; end

  # Error raised on a 404 response.
  class ResourceNotFound < Error; end

  # Error raised on a 401 response.
  class UnauthorizedError < Error; end

  # Creates a virtual host.
  #
  # @param incoming_address [String] The incoming address.
  # @param target_address [String] The target address.
  # @param options [Hash] Optional fields. See https://approximated.app/docs/#create-virtual-host for more details.
  #
  # @return [Approximated::Result]
  #
  # @raise [Approximated::UnauthorizedError] If the API key does not exist.
  #
  def create_vhost(incoming_address, target_address, options = {})
    handle_exceptions do
      data = options.merge({ incoming_address:, target_address: })
      response = connection.post('/api/vhosts', data)
      handle_response(response)
    end
  end

  # Updates a virtual host.
  # Any fields not passed into options will remain the same.
  #
  # @param current_incoming_address [String] The current incoming address.
  # @param options [Hash] Optional fields. See https://approximated.app/docs/#update-virtual-host for more details.
  #
  # @return [Approximated::Result]
  #
  # @raise [Approximated::UnauthorizedError] If the API key does not exist.
  # @raise [Approximated::ResourceNotFound] If the virtual host could not be found.
  #
  def update_vhost(current_incoming_address, options = {})
    handle_exceptions do
      data = options.merge({ current_incoming_address: })
      response = connection.post('/api/vhosts/update/by/incoming', data)
      handle_response(response)
    end
  end

  # Reads a virtual host.
  #
  # @param incoming_address [String] The incoming address.
  #
  # @return [Approximated::Result]
  #
  # @raise [Approximated::UnauthorizedError] If the API key does not exist.
  # @raise [Approximated::ResourceNotFound] If the virtual host could not be found.
  #
  def get_vhost(incoming_address)
    handle_exceptions do
      response = connection.get("/api/vhosts/by/incoming/#{incoming_address}")
      handle_response(response)
    end
  end

  # Deletes a virtual host.
  #
  # @param incoming_address [String] The incoming address.
  #
  # @return [Approximated::Result]
  #
  # @raise [Approximated::UnauthorizedError] If the API key does not exist.
  # @raise [Approximated::ResourceNotFound] If the virtual host could not be found.
  #
  def delete_vhost(incoming_address)
    handle_exceptions do
      response = connection.delete("/api/vhosts/by/incoming/#{incoming_address}")
      handle_response(response)
    end
  end

  private

  def connection
    @connection ||= Faraday.new(
      url: 'https://cloud.approximated.app/',
      headers: { 'api-key' => ENV.fetch('APPROXIMATED_API_KEY') }
    ) do |faraday|
      faraday.request :json
      faraday.response :json, preserve_raw: true
      faraday.response :raise_error
    end
  end

  def handle_response(response)
    Result.new(status: response.status, body: response.body)
  end

  def handle_exceptions
    yield
  rescue Faraday::UnauthorizedError
    raise UnauthorizedError
  rescue Faraday::ResourceNotFound
    raise ResourceNotFound
  rescue Faraday::Error
    raise Error
  end
end
