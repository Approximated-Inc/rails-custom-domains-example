# frozen_string_literal: true

class CustomDomainsController < ApplicationController
  before_action :require_tenant!

  def index
    return unless current_tenant

    @custom_domains = current_tenant.custom_domains.order(:hostname)
  end

  def create
    DomainLifecycle.new(tenant: current_tenant).add(params.require(:hostname))
    redirect_to control_root_path, notice: 'Domain provisioning started.'
  rescue DomainName::Invalid, DomainLifecycle::Conflict, DomainLifecycle::ReconciliationRequired,
         ActiveRecord::RecordInvalid, Approximated::ApiError => e
    redirect_to control_root_path, alert: e.message
  end

  def refresh
    domain = DomainLifecycle.new(tenant: current_tenant).refresh(params[:id])
    message = domain ? 'Domain status refreshed.' : 'Provider deletion confirmed; reservation released.'
    redirect_to control_root_path, notice: message
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue DomainLifecycle::ReconciliationRequired, Approximated::ApiError => e
    redirect_to control_root_path, alert: e.message
  end

  def destroy
    DomainLifecycle.new(tenant: current_tenant).remove(params[:id])
    redirect_to control_root_path, notice: 'Removal started; the reservation remains until provider GET returns 404.'
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue DomainLifecycle::ReconciliationRequired, Approximated::ApiError => e
    redirect_to control_root_path, alert: e.message
  end
end
