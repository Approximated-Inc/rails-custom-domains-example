# frozen_string_literal: true

class CustomDomainValidator < ActiveModel::EachValidator
  RESERVED_DOMAINS = [ENV.fetch('APP_PRIMARY_DOMAIN')].freeze

  def validate_each(record, attribute, value)
    return if value.blank?
    return if valid_custom_domain?(value)

    record.errors.add(attribute, options[:message] || :invalid)
  end

  private

  def valid_custom_domain?(value)
    return false if RESERVED_DOMAINS.include?(value.downcase)

    # Strictly validate domain (without the default "*" rule)
    return false unless PublicSuffix.valid?(value, default_rule: nil)

    true
  rescue PublicSuffixService::DomainNotAllowed
    false
  end
end
