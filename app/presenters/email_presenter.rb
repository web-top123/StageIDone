class EmailPresenter
  include Rails.application.routes.url_helpers

  attr_accessor :recipient, :user, :team, :team_membership

  def initialize(team_membership)
    @team_membership = team_membership
    @recipient = team_membership.user
    @team = team_membership.team
  end
  
  def unsubscribe_digests_url
    unsubscribe_digests_team_team_membership_url(
      team_id: @team.hash_id,
      id: @team_membership.id
    )
  end

  def unsubscribe_reminders_url
    unsubscribe_reminders_team_team_membership_url(
      team_id: @team.hash_id,
      id: @team_membership.id
    )
  end

  def unsubscribe_assign_task_reminders_url
    unsubscribe_assign_task_reminders_team_team_membership_url(
      team_id: @team.hash_id,
      id: @team_membership.id
    )
  end

  def unsubscribe_mentions_notification_url
    unsubscribe_mentions_notification_team_team_membership_url(
      team_id: @team.hash_id,
      id: @team_membership.id,
    )
  end

  def unsubscribe_comments_notification_url
    unsubscribe_comments_notification_team_team_membership_url(
      team_id: @team.hash_id,
      id: @team_membership.id,
    )
  end
end
