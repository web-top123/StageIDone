class StripeController < ApplicationController
  skip_after_action :verify_authorized
  protect_from_forgery except: :hook

  ## !!!IMPORTANT!!!
  ## If you change the events processed here, please make sure you have the stripe webhook
  ## updated too as we only subscribe to the events listed here for the IDT2 webhook rather 
  ## than be hit with every Stripe event
  ## !!!IMPORTANT!!!
  def hook
    event = Stripe::Event.retrieve(params[:id])

    case event.type
    when 'customer.subscription.updated', 'customer.subscription.created'
      subscription_updated(event)
    when 'charge.failed'
      charge_failed(event)
    when 'plan.created'
      plan_created(event)
    when 'customer.subscription.deleted'
      subscription_cancelled(event)
    end
    render nothing: true
  end

  private

  def subscription_cancelled(event)
    stripe_customer_id = event.data.object.customer
    organization       = Organization.find_by(stripe_customer_token: stripe_customer_id)
    return if organization.nil? # Make sure it concerns idt2 and not idt1

    subscription = event.data.object

    if organization.present? 
      organization.update stripe_subscription_status: subscription.status, plan_level: nil, plan_interval: nil
    end
  end

  def subscription_updated(event)
    stripe_customer_id = event.data.object.customer
    organization       = Organization.find_by(stripe_customer_token: stripe_customer_id)
    return if organization.nil? # Make sure it concerns idt2 and not idt1

    subscription = event.data.object
    plan         = subscription.plan.id

    subscription_attrs = {stripe_subscription_status: subscription.status}

    if AppSetting.stripe_plan_id_to_internal(plan).nil?
      Raven.capture_message "Customer was upgraded to invalid plan", extra: { stripe_customer_id: stripe_customer_id.to_s, plan_id: plan.to_s }
    else
      plan_level, plan_interval = AppSetting.stripe_plan_id_to_internal(plan)
      subscription_attrs[:plan_level]    = plan_level
      subscription_attrs[:plan_interval] = plan_interval
    end

    organization.update_columns(subscription_attrs) # avoid callbacks that will send updates to Stripe
  end

  def charge_failed(event)
    stripe_customer_id = event.data.object.customer
    Raven.capture_message "Failed charge for customer", extra: { stripe_customer_id: stripe_customer_id.to_s }
  end

  def plan_created(event)
    plan_id = event.data.object.id
    if AppSetting.stripe_plan_id_to_internal(plan_id).nil?
      Raven.capture_message "Plan created with faulty ID", extra: { plan_id: plan_id.to_s }
    end
  end
end
