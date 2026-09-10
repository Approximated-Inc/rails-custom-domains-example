# frozen_string_literal: true

class PublicPagesController < ApplicationController
  layout 'public'

  def show
    domain = CustomDomain.routable.includes(:tenant).find_by!(hostname: RequestedHost.call(request))
    @tenant = domain.tenant
    response.headers['Cache-Control'] = 'private, no-store'
  rescue DomainName::Invalid, ActiveRecord::RecordNotFound
    head :not_found
  end
end
