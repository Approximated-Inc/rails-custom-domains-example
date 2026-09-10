# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :require_local_fixture_login!

  def new; end

  def create
    tenant = Tenant.find_by(slug: params[:tenant_slug])
    expected = ENV.fetch('DEMO_LOGIN_PASSWORD', 'demo-only')
    supplied = params[:password].to_s

    if tenant && supplied.bytesize == expected.bytesize && ActiveSupport::SecurityUtils.secure_compare(supplied,
                                                                                                       expected)
      reset_session
      session[:tenant_id] = tenant.id
      redirect_to control_root_path, notice: "Signed in as #{tenant.name}."
    else
      redirect_to new_session_path, alert: 'Invalid fixture credentials.'
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: 'Signed out.'
  end

  private

  def require_local_fixture_login!
    return if Rails.env.local? && ControlHostConstraint.matches?(request)

    raise ActionController::RoutingError, 'Not Found'
  end
end
