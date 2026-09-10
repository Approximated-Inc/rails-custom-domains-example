# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protect_from_forgery with: :exception

  helper_method :current_tenant

  private

  def current_tenant
    return @current_tenant if defined?(@current_tenant)

    @current_tenant = Tenant.find_by(id: session[:tenant_id])
  end

  def require_tenant!
    redirect_to new_session_path, alert: 'Sign in to manage domains.' unless current_tenant
  end
end
