# frozen_string_literal: true

class AppDomainConstraint
  def self.matches?(request)
    requested_host = request.headers['apx-incoming-host'].presence || request.host
    requested_host.blank? || requested_host == ENV.fetch('APP_PRIMARY_DOMAIN')
  end
end
