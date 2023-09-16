class IntercomApi
  def self.intercom
    Intercom::Client.new(token: ENV["INTERCOM_API_KEY"])
    # Intercom::Client.new(app_id: ENV["INTERCOM_APP_ID"], api_key: ENV["INTERCOM_API_KEY"])
  end

  def self.upsert_user(user)
    intercom.users.create(user_params(user))
  end

  def self.upsert_users(users)
    intercom.users.submit_bulk_job(create_items: users.collect {|user| user_params(user) } )
  end

  def self.user_params(user)
    {
      email: user.email_address,
      name: user.full_name,
      user_id: user.id,
      phone: user.phone_number,
      created_at: user.created_at.to_i,
      custom_attributes: {
        on_idt_two: true,
        synched_at: Time.now.utc.to_i,
        deleted_at: user.deleted_at.to_i,
        done_count: user.entries.dones.count,
        goal_count: user.entries.goals.count,
        blocker_count: user.entries.blockers.count,
        like_count: user.reactions.is_like.count,
        comment_count: user.reactions.is_comment.count,
        unpaid_organization_count: user.organizations.where.not(stripe_subscription_status: ['active', 'trialing']).count,
        paid_organization_count: user.organizations.where(stripe_subscription_status: ['active', 'trialing']).count,
        plan_interval: user.organizations.where(stripe_subscription_status: ['active', 'trialing']).first.try(:plan_interval),
        plan_level: user.organizations.where(stripe_subscription_status: ['active', 'trialing']).first.try(:plan_level),
        is_organization_owner: user.organization_memberships.owned.any?,
        users_invited: user.invitations_sent.count,
        integration_types: user.integration_users.pluck(:integration_type).join(', ')
      }
    }
  end
end
