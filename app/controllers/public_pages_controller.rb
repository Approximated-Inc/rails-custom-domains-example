# frozen_string_literal: true

class PublicPagesController < ApplicationController
  layout 'public'

  def show
    @page = Page.find_by!(domain: requested_host)
  end

  private

  def requested_host
    request.headers['apx-incoming-host'].presence || request.host
  end
end
