class SessionsPolicy < ApplicationPolicy
  def create?
    user == record
  end
end
