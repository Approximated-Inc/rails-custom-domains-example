# frozen_string_literal: true

require 'ipaddr'

class DomainName
  class Invalid < StandardError; end

  LABEL = /\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/

  def self.normalize(input, allow_control: false)
    value = input.to_s.strip.delete_suffix('.')
    if value.blank? || value.match?(%r{[/:\\*]})
      raise Invalid,
            'Enter a hostname without a scheme, path, wildcard, or port.'
    end

    ascii = SimpleIDN.to_ascii(value).downcase
    control_host = SimpleIDN.to_ascii(ENV.fetch('CONTROL_HOST', 'localhost').downcase.delete_suffix('.'))
    return ascii if allow_control && ascii == control_host

    labels = ascii.split('.', -1)
    raise Invalid, 'Enter a complete domain name.' if labels.length < 2 || ascii.bytesize > 253
    raise Invalid, 'Enter a valid domain name.' unless labels.all? do |label|
      label.bytesize.between?(1, 63) && label.match?(LABEL)
    end
    if ip_address?(ascii) || ascii.end_with?('.localhost')
      raise Invalid,
            'IP addresses and local hosts are not custom domains.'
    end

    raise Invalid, 'The control host cannot be claimed as a custom domain.' if !allow_control && ascii == control_host

    ascii
  rescue SimpleIDN::ConversionError
    raise Invalid, 'Enter a valid internationalized domain name.'
  end

  def self.ip_address?(value)
    IPAddr.new(value)
    true
  rescue IPAddr::InvalidAddressError
    false
  end
  private_class_method :ip_address?
end
