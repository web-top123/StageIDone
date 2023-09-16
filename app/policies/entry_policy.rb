class EntryPolicy < ApplicationPolicy
  def create?
    (user.personal_team == record.team) or
    record.team.active_users.include? user
  end

  def brief? # basically 'show'
    team = record.team

    # copied from team, should really defer to that method

    (user.personal_team == team) or
    team.active_users.include?(user) or
    (!team.personal? && team.organization.owners.include?(user)) or
    (!team.personal? && team.organization.admins.include?(user)) or
    (!team.personal? && !team.private? && team.organization.active_users.include?(user))
  end

  def edit?
    record.user == user
  end

  def update?
    edit?
  end

  def destroy?
    edit? &&
    record.reactions.includes(:reactions).empty?
  end

  def assign?
    edit?
    # record.reactions.empty?
  end

  def toggle_like?
    (user.personal_team == record.team) or
    record.team.active_users.include? user
  end

  def mark_done?
    (record.user == user)
  end

  def archive?
    (record.user == user)
  end
end
