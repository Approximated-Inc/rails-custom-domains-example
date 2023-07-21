# frozen_string_literal: true

module TestSupport
  module ApproximatedHelpers
    def stub_apx_create_request(scenario, body:)
      case scenario
      when :success
        stub_apx_request('/api/vhosts', :post, body, 201, 'create.json')
      when :unauthorized
        stub_apx_request('/api/vhosts', :post, body, 401, nil)
      else
        raise ArgumentError, 'Unknown scenario'
      end
    end

    def stub_apx_update_request(scenario, body:)
      case scenario
      when :success
        stub_apx_request('/api/vhosts/update/by/incoming', :post, body, 200, 'update.json')
      when :unauthorized
        stub_apx_request('/api/vhosts/update/by/incoming', :post, body, 401, nil)
      when :not_found
        stub_apx_request('/api/vhosts/update/by/incoming', :post, body, 404, nil)
      else
        raise ArgumentError, 'Unknown scenario'
      end
    end

    def stub_apx_read_request(scenario, incoming_address:)
      case scenario
      when :success
        stub_apx_request("/api/vhosts/by/incoming/#{incoming_address}", :get, '', 200, 'read.json')
      when :unauthorized
        stub_apx_request("/api/vhosts/by/incoming/#{incoming_address}", :get, '', 401, nil)
      when :not_found
        stub_apx_request("/api/vhosts/by/incoming/#{incoming_address}", :get, '', 404, nil)
      else
        raise ArgumentError, 'Unknown scenario'
      end
    end

    def stub_apx_delete_request(scenario, incoming_address:)
      case scenario
      when :success
        stub_apx_request("/api/vhosts/by/incoming/#{incoming_address}", :delete, '', 200, nil)
      when :unauthorized
        stub_apx_request("/api/vhosts/by/incoming/#{incoming_address}", :delete, '', 401, nil)
      when :not_found
        stub_apx_request("/api/vhosts/by/incoming/#{incoming_address}", :delete, '', 404, nil)
      else
        raise ArgumentError, 'Unknown scenario'
      end
    end

    private

    def stub_apx_request(path, method, request_body, status, response_file)
      request_url = URI::HTTPS.build(host: 'cloud.approximated.app', path:).to_s
      response_body = response_file ? file_fixture(File.join('approximated', response_file)).read : nil

      stub_request(method, request_url).with(
        body: request_body,
        headers: { 'api-key' => ENV.fetch('APPROXIMATED_API_KEY') }
      ).to_return(
        status:,
        body: response_body,
        headers: { 'Content-Type' => 'application/json' }
      )

      response_body.present? ? JSON.parse(response_body) : response_body
    end
  end
end
