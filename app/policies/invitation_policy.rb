class InvitationPolicy < ApplicationPolicy
  def index?
    true
  end

  def accept?
    record.email_address == user.email_address  
  end

  def decline?
    accept?
  end

  def create?
    record.organization.active_users.include? user
  end

  def resend?
    create?
  end

  def destroy?
    create?
  end
end