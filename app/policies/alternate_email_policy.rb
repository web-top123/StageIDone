class AlternateEmailPolicy < ApplicationPolicy
  def create?
    record.user == user
  end

  def destroy?
    create?
  end

  def verify?
    true
  end
end
