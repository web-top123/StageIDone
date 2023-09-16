class TeamPolicy < ApplicationPolicy
  def new?
    record.organization.active_users.include? user
  end

  def create?
    new?
  end

  def show?
    (user.personal_team == record) or
    record.active_users.include?(user) or
    (!record.personal? && record.organization.owners.include?(user)) or
    (!record.personal? && record.organization.admins.include?(user)) or
    (!record.personal? && !record.private? && record.organization.active_users.include?(user))
  end

  def search?
    show?
  end

  def export?
    show?
  end

  def calendar?
    show?
  end

  def tag?
    show?
  end

  def update?
    (user.personal_team == record) or
    record.active_users.include?(user) or
    (!record.personal? && record.organization.owners.include?(user)) or
    (!record.personal? && record.organization.admins.include?(user)) or
    (!record.personal? && !record.private? && record.organization.active_users.include?(user))
  end

  def settings?
    update?
  end

  def customize?
    update?
  end

  def calendar_month?
    show?
  end

  def brief?
    show?
  end

  def stats?
    show?
  end

  def destroy?
    # (record.personal? && record.active_users.include?(user)) or
    # (record.organization.owners.include?(user)) or
    # (record.organization.admins.include?(user))
    (record.personal? && record.active_users.include?(user)) or
    (record.owner_id == user.id || record.organization.owners.include?(user))
  end

  def user_entry_listing?
    show?
  end
end