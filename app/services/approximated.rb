# frozen_string_literal: true

class Approximated
  CLOUD_API_URL = 'https://cloud.approximated.app'
  BOOLEAN_OR_NIL = [true, false, nil].freeze
  Vhost = Data.define(:id, :incoming_address, :status, :status_message, :user_message, :is_resolving, :apx_hit,
                      :has_ssl, :dns_pointed_at)

  class ApiError < StandardError; end
  class NotFound < ApiError; end
  class InvalidResponse < ApiError; end

  class << self
    def mode(env: ENV)
      override = env.fetch('APPROXIMATED_MODE', '').to_s.strip.downcase
      raise ApiError, 'APPROXIMATED_MODE must be blank, mock, or real.' unless ['', 'mock', 'real'].include?(override)

      api_key = env.fetch('APPROXIMATED_API_KEY', '').to_s.strip
      return :mock if override == 'mock' || (override.empty? && api_key.empty?)
      raise ApiError, 'An Approximated API key is required in real mode.' if api_key.empty?

      :real
    end

    def configured(env: ENV)
      return Mock.new if mode(env:) == :mock

      target_address = env.fetch('APP_ORIGIN_HOST', '').to_s.strip
      raise ApiError, 'APP_ORIGIN_HOST is required in real mode.' if target_address.empty?

      new(
        api_key: env.fetch('APPROXIMATED_API_KEY').to_s.strip,
        target_address:,
        base_url: CLOUD_API_URL
      )
    end
  end

  class Mock
    class << self
      def create(hostname)
        mutex.synchronize do
          @next_id = (@next_id || 100_000) + 1
          records[@next_id] = Vhost.new(
            id: @next_id,
            incoming_address: hostname,
            status: 'local mock',
            status_message: 'Simulated readiness from the local mock.',
            user_message: 'This domain status is simulated; no external API request was sent.',
            is_resolving: true,
            apx_hit: true,
            has_ssl: true,
            dns_pointed_at: 'simulated'
          )
        end
      end

      def get(id)
        mutex.synchronize { records[Integer(id)] } || raise(NotFound, 'Local mock virtual host not found.')
      end

      def delete(id)
        mutex.synchronize { records.delete(Integer(id)) }
        nil
      end

      private

      def records
        @records ||= {}
      end

      def mutex
        @mutex ||= Mutex.new
      end
    end

    delegate :create, :get, :delete, to: :class
  end

  attr_reader :base_url

  def initialize(api_key: ENV.fetch('APPROXIMATED_API_KEY'),
                 target_address: ENV.fetch('APP_ORIGIN_HOST'),
                 base_url: ENV.fetch('APPROXIMATED_API_URL', CLOUD_API_URL),
                 timeout: 5)
    @api_key = api_key
    @target_address = target_address
    @base_url = base_url
    @timeout = timeout
  end

  def create(hostname)
    response = request(:post, '/api/vhosts', {
                         incoming_address: hostname,
                         target_address: @target_address,
                         target_ports: '443',
                         keep_host: true
                       })
    parse_vhost(response)
  end

  def get(id)
    parse_vhost(request(:get, "/api/vhosts/#{Integer(id)}"))
  end

  def delete(id)
    request(:delete, "/api/vhosts/#{Integer(id)}")
    nil
  end

  private

  def connection
    @connection ||= Faraday.new(
      url: @base_url,
      headers: { 'api-key' => @api_key, 'Accept' => 'application/json' }
    ) do |faraday|
      faraday.request :json
      faraday.options.timeout = @timeout
      faraday.options.open_timeout = @timeout
    end
  end

  def request(method, path, body = nil)
    response = connection.public_send(method, path, body)
    raise NotFound, 'Approximated virtual host not found.' if response.status == 404
    raise ApiError, "Approximated returned HTTP #{response.status}: #{response.body}" unless response.success?

    response
  rescue Faraday::TimeoutError
    raise ApiError, 'Approximated request timed out.'
  rescue Faraday::Error => e
    raise ApiError, "Approximated request failed: #{e.message}"
  end

  def parse_vhost(response)
    data = JSON.parse(response.body).fetch('data')
    raise InvalidResponse, 'Approximated returned malformed virtual-host JSON.' unless data.is_a?(Hash)

    id = data.fetch('id')
    incoming_address = data.fetch('incoming_address')
    unless id.is_a?(Integer) && id.positive? && incoming_address.is_a?(String) && incoming_address.present?
      raise InvalidResponse,
            'Approximated returned an invalid virtual-host identity.'
    end

    %w[is_resolving apx_hit has_ssl].each do |field|
      raise InvalidResponse, "Approximated returned an invalid #{field}." unless BOOLEAN_OR_NIL.include?(data[field])
    end
    status = data.fetch('status', 'pending')
    status_message = data['status_message']
    user_message = data['user_message']
    dns_pointed_at = data['dns_pointed_at']
    raise InvalidResponse, 'Approximated returned an invalid status.' unless status.is_a?(String)

    { status_message:, user_message:, dns_pointed_at: }.each do |field, value|
      raise InvalidResponse, "Approximated returned an invalid #{field}." unless value.nil? || value.is_a?(String)
    end

    Vhost.new(
      id:,
      incoming_address:,
      status:,
      status_message:,
      user_message:,
      is_resolving: data['is_resolving'],
      apx_hit: data['apx_hit'],
      has_ssl: data['has_ssl'],
      dns_pointed_at:
    )
  rescue JSON::ParserError, KeyError, TypeError
    raise InvalidResponse, 'Approximated returned malformed virtual-host JSON.'
  end
end
