class OrganizationMembershipPolicy < ApplicationPolicy
  def index?
    om = record.first
    om.organization.owners.include?(user) ||
    om.organization.admins.include?(user)
  end

  def edit?
    not_yourself? &&
    can_change_role? &&
    organization_admin_or_owner?
  end

  def update?
    not_yourself? &&
    organization_admin_or_owner? &&
    valid_role_change?
  end

  def destroy?
    organization_owner?
  end

  def authorized_roles
    if organization_owner?
      owner_authorized_roles
    elsif organization_admin?
      admin_authorized_roles
    else
      []
    end
  end

  private

  def not_yourself?
    user != record.user
  end

  def organization_admin_or_owner?
    organization_owner? ||
    organization_admin?
  end

  def organization_admin?
    record.organization.admins.include?(user)
  end

  def organization_owner?
    record.organization.owners.include?(user)
  end

  def old_role
    record.role_was
  end

  def new_role
    record.role
  end

  def admin_authorized_roles
    %w(admin member)
  end

  def owner_authorized_roles
    %w(owner admin member)
  end

  def can_change_role?
    authorized_roles.include?(record.role)
  end

  def valid_role_change?
    authorized_roles.include?(new_role) &&
    authorized_roles.include?(old_role)
  end
end
