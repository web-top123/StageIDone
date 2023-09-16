class Admin::DashboardController < Admin::ApplicationController
  def acquisition
    @weeks = 20.times.map do |i|
      week_start = (Time.zone.now - i.weeks).beginning_of_week
      week_end = (Time.zone.now - i.weeks).end_of_week

      users_created_this_week = User.where(migrated_from_legacy_at: nil).where(created_at: week_start..week_end)
      organizations_created_this_week = Organization.where('organizations.created_at >= ?', week_start).joins(:users).merge(users_created_this_week).uniq

      {
        monday: week_start,
        acquisition: users_created_this_week.count,
        activation: users_created_this_week.has_three_entries.count,
        retention: users_created_this_week.has_recent_entries.count,
        referral: organizations_created_this_week.joins(:invitations).merge( Invitation.redeemed ).uniq.count,
        revenue: organizations_created_this_week.where(stripe_subscription_status: 'active').map(&:estimated_mrr).sum
      }
    end
  end

  def migration
    @weeks = 20.times.map do |i|
      week_start = (Time.zone.now - i.weeks).beginning_of_week
      week_end = (Time.zone.now - i.weeks).end_of_week

      users_migrated_this_week = User.where.not(migrated_from_legacy_at: nil).where(created_at: week_start..week_end)
      orgs_migrated_this_week = Organization.joins(:users).merge(users_migrated_this_week).uniq
      logged_in_this_week = users_migrated_this_week.where('last_seen_at > migrated_from_legacy_at')

      {
        monday: week_start,
        migrated_orgs: orgs_migrated_this_week.count,
        migrated_users: users_migrated_this_week.count,
        logged_in_users: logged_in_this_week.count
      }
    end
  end

  def usage
    entries_series  = {}
    comments_series = {}
    likes_series    = {}
    @weeks = 20.times.map do |i|
      week_start = (Time.zone.now - i.weeks).beginning_of_week
      week_end = (Time.zone.now - i.weeks).end_of_week
      entries  = Entry.where(created_at: week_start..week_end).count
      comments = Reaction.where(created_at: week_start..week_end).is_comment.count
      likes    = Reaction.where(created_at: week_start..week_end).is_like.count
      entries_series[week_start]  = entries
      comments_series[week_start] = comments
      likes_series[week_start]    = likes
      {
        monday: week_start,
        entries: entries,
        comments: comments,
        likes: likes
      }
    end
    @graph_data = [{name: 'entries', data: entries_series}, {name: 'comments', data: comments_series}, {name: 'likes', data: likes_series}]
  end
end
