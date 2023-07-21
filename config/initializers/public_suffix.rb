# frozen_string_literal: true

if Rails.env.development?
  # Allow test domain in development env
  PublicSuffix::List.default << PublicSuffix::Rule.factory('test')
end
