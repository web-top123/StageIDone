class OrganizationPolicy < ApplicationPolicy
  def new?
    true
  end

  def create?
    new?
  end

  def show?
    record.users.include? user
  end

  def stats?
    show?
  end

  def tag?
    show?
  end

  def export?
    show?
  end

  def user?
    show?
  end

  def upgrade?
    record.owners.include?(user) or
    record.admins.include?(user) or
    show?
  end

  def settings?
    record.owners.include?(user) or
    record.admins.include?(user)
  end

  def update?
    record.owners.include?(user) or
    record.admins.include?(user)
  end

  def customize?
    record.owners.include?(user) or
    record.admins.include?(user)
  end

  def saml_save?
    record.owners.include?(user) or
    record.admins.include?(user)
  end

  def billing?
    record.owners.include?(user)
  end

  def billing_form?
    record.owners.include?(user)
  end

  def billing_save?
    record.owners.include?(user)
  end

  def invoices?
    record.owners.include?(user)
  end

  def overdue?
    record.users.include?(user)
  end
end