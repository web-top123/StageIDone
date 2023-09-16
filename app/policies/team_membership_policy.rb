class TeamMembershipPolicy < ApplicationPolicy
  def create?
    (!record.team.private? && record.team.organization.active_users.include?(user)) or
    record.team.active_users.include?(user) or
    record.team.organization.owners.include?(user) or
    record.team.organization.admins.include?(user)
  end

  def update?
    record.team.active_users.include?(user) or
    record.team.organization.owners.include?(user) or
    record.team.organization.admins.include?(user)
  end

  def notifications?
    update?
  end

  def notifications_save?
    update?
  end

  def unsubscribe_comments_notification?
    update?
  end

  def unsubscribe_mentions_notification?
    update?
  end
  def unsubscribe_digests?
    update?
  end

  def unsubscribe_reminders?
    update?
  end

  def destroy?
    update?
  end
end
