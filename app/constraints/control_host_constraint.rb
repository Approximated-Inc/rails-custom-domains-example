# frozen_string_literal: true

class ControlHostConstraint
  def self.matches?(request)
    RequestedHost.call(request) == ENV.fetch('CONTROL_HOST', 'localhost').downcase
  rescue DomainName::Invalid
    false
  end
end
