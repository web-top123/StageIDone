class NotificationPolicy < ApplicationPolicy
  def index?
    true
  end

  def clear?
    true
  end

  def destroy?
    true
  end

  def reload_archived?
  	true
  end
end
