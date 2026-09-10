# frozen_string_literal: true

require 'test_helper'
require 'socket'

class ApproximatedHttpTest < ActiveSupport::TestCase
  class LocalStub
    attr_reader :port, :requests

    def initialize(responses)
      @server = TCPServer.new('127.0.0.1', 0)
      @port = @server.addr[1]
      @requests = []
      @thread = Thread.new do
        responses.each do |response|
          socket = @server.accept
          request_line = socket.gets
          headers = {}
          while (line = socket.gets) && line != "\r\n"
            name, value = line.split(':', 2)
            headers[name.downcase] = value.strip
          end
          body = socket.read(headers.fetch('content-length', '0').to_i)
          @requests << { request_line:, headers:, body: }
          status, content_type, response_body = response
          socket.write("HTTP/1.1 #{status}\r\nContent-Type: #{content_type}\r\n")
          socket.write("Content-Length: #{response_body.bytesize}\r\nConnection: close\r\n\r\n#{response_body}")
          socket.close
        end
      ensure
        @server.close
      end
    end

    def finish
      raise 'local HTTP stub did not finish' unless @thread.join(2)

      @thread.value
    end
  end

  test 'uses the documented POST GET DELETE contract over real HTTP' do
    create_body = { data: { id: 72, incoming_address: 'alpha.example.com',
                            user_message: 'Add the DNS record.' } }.to_json
    get_body = { data: { id: 72, incoming_address: 'alpha.example.com', status: 'ready', status_message: 'Serving',
                         is_resolving: true, apx_hit: true, has_ssl: false, dns_pointed_at: '192.0.2.10' } }.to_json
    stub = LocalStub.new([
                           ['200 OK', 'application/json', create_body],
                           ['200 OK', 'application/json', get_body],
                           ['200 OK', 'text/plain', 'Deleting alpha.example.com']
                         ])
    client = client_for(stub)

    created = client.create('alpha.example.com')
    refreshed = client.get(72)
    client.delete(72)
    stub.finish

    assert_equal 'pending', created.status
    assert_nil created.status_message
    assert_nil created.is_resolving
    assert_nil created.apx_hit
    assert_nil created.has_ssl
    assert refreshed.is_resolving
    assert refreshed.apx_hit
    assert_not refreshed.has_ssl
    expected_paths = ['POST /api/vhosts HTTP/1.1', 'GET /api/vhosts/72 HTTP/1.1',
                      'DELETE /api/vhosts/72 HTTP/1.1']

    assert_equal(expected_paths, stub.requests.map do |request|
      request[:request_line].strip
    end)
    assert_equal ['test-key'], stub.requests.map { |request| request[:headers]['api-key'] }.uniq
    assert_equal(
      { 'incoming_address' => 'alpha.example.com', 'target_address' => 'origin.test', 'target_ports' => '443',
        'keep_host' => true }, JSON.parse(stub.requests.first[:body])
    )
  end

  test 'rejects malformed JSON and wrong optional field types' do
    stub = LocalStub.new([
                           ['200 OK', 'application/json', '{bad'],
                           ['200 OK', 'application/json', { data: 42 }.to_json],
                           ['200 OK', 'application/json',
                            { data: { id: 72, incoming_address: 'alpha.example.com', status: 42 } }.to_json],
                           ['200 OK', 'application/json',
                            { data: { id: 72, incoming_address: 'alpha.example.com', status_message: 42 } }.to_json],
                           ['200 OK', 'application/json',
                            { data: { id: 72, incoming_address: 'alpha.example.com', is_resolving: 'yes' } }.to_json],
                           ['200 OK', 'application/json',
                            { data: { id: 72, incoming_address: 'alpha.example.com', apx_hit: 'yes' } }.to_json],
                           ['200 OK', 'application/json',
                            { data: { id: 72, incoming_address: 'alpha.example.com', has_ssl: 'yes' } }.to_json]
                         ])
    client = client_for(stub)

    assert_raises(Approximated::InvalidResponse) { client.get(72) }
    assert_raises(Approximated::InvalidResponse) { client.get(72) }
    assert_raises(Approximated::InvalidResponse) { client.get(72) }
    assert_raises(Approximated::InvalidResponse) { client.get(72) }
    assert_raises(Approximated::InvalidResponse) { client.get(72) }
    assert_raises(Approximated::InvalidResponse) { client.get(72) }
    assert_raises(Approximated::InvalidResponse) { client.get(72) }
    stub.finish
  end

  test 'maps 404 and bounded read timeout without using the live API' do
    stub = LocalStub.new([['404 Not Found', 'text/plain', 'missing']])
    assert_raises(Approximated::NotFound) { client_for(stub).get(72) }
    stub.finish

    server = TCPServer.new('127.0.0.1', 0)
    release = Queue.new
    thread = Thread.new do
      socket = server.accept
      socket.gets
      release.pop
      socket.close
    ensure
      server.close
    end
    client = Approximated.new(api_key: 'test-key', target_address: 'origin.test',
                              base_url: "http://127.0.0.1:#{server.addr[1]}", timeout: 0.02)

    assert_raises(Approximated::ApiError) { client.get(72) }
  ensure
    release&.push(true)
    thread&.join(2)
  end

  private

  def client_for(stub)
    Approximated.new(api_key: 'test-key', target_address: 'origin.test', base_url: "http://127.0.0.1:#{stub.port}",
                     timeout: 1)
  end
end
