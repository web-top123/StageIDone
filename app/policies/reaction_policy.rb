class ReactionPolicy < ApplicationPolicy
  def show
    team = record.reactable.team

    # copied from team, should really defer to that method

    (user.personal_team == team) or
    team.active_users.include?(user) or
    (!team.personal? && team.organization.owners.include?(user)) or
    (!team.personal? && team.organization.admins.include?(user)) or
    (!team.personal? && !team.private? && team.organization.active_users.include?(user))
  end

  def create?
    record.reactable.team.users.include? user
  end

  def edit?
    record.comment? && (record.user == user)
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end
end