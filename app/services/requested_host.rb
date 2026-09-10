# frozen_string_literal: true

class RequestedHost
  def self.call(request)
    raw = request.get_header('HTTP_HOST').presence || request.host
    raw = raw.delete_prefix('[').split(']', 2).first if raw.start_with?('[')
    raw = raw.sub(/:\d+\z/, '')
    DomainName.normalize(raw, allow_control: true)
  end
end
