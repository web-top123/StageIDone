class UpgradeController < ApplicationController
  before_action :require_login

  layout 'modal'

  def subcription_failes
    @organization = Organization.find_by(hash_id: params[:organization_id])

    authorize @organization, :upgrade?

    render 'subcription_failes'
  end

  def show
    @organization = current_organization

    authorize @organization, :upgrade?

    render 'choose_plan'
  end

  def billing
    @organization = current_organization
    @organization.plan_level = params[:plan].downcase
    @organization.plan_interval = params[:interval].downcase
    authorize @organization, :upgrade?
    if @organization.plan_interval.blank?
      @organization.plan_interval = 'yearly'
    end
    if @organization.billable_card_on_file? && @organization.save
      if @organization.stripe_customer && @organization.stripe_customer.subscriptions.any?
        stripe_subscription = @organization.stripe_customer.subscriptions.first
        @organization.update_attributes(stripe_subscription_status: stripe_subscription.status)
      elsif @organization.stripe_customer && @organization.stripe_customer.subscriptions.any? == false
        if @organization.stripe_customer.sources.any? == false
          redirect_to('/onboard/one')
        else
          # create subscription with new credit card
          subscription = Stripe::Subscription.create(
            customer:    @organization.stripe_customer_token,
            plan:        @organization.plan_stripe_id,
            quantity:    @organization.users.count,
            trial_end:   @organization.on_trial? ? @organization.trial_ends_at.to_i : 'now'
          )

          @organization.stripe_subscription_status = subscription.status
          @organization.save
        end
      end
      flash[:notice] = "Your organization's plan has successfully been updated."
      redirect_to [:settings, @organization]
      return
    else
      render 'card_details'
    end
  end

  def complete
    @organization = current_organization

    authorize @organization, :upgrade?

    if @organization.update_attributes(organization_params)
      flash[:notice] = "Your organization is all set. Thanks for choosing I Done This."
      redirect_to @organization
      return
    end
    render 'card_details'
  end

  private

  def current_organization
    @current_organization ||= current_user.owned_organizations.find_by(hash_id: params[:organization_id])
  end

  def organization_params
    params.require(:organization).permit(:plan_interval, :plan_level, :billing_name, :stripe_token)
  end
end
