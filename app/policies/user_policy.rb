class UserPolicy < ApplicationPolicy
  def update?
    user == record
  end

  def personalize?
    update?
  end

  def settings?
    update?
  end

  def change_password?
    update?
  end

  def migrate_one?
    update?
  end

  def migrate_one_save?
    update?
  end

  def migrate_two?
    update?
  end

  def migrate_two_save?
    update?
  end

  def onboard_notice?
    update?
  end 

  def onboard_one?
    update?
  end

  def onboard_one_save?
    update?
  end

  def onboard_two?
    update?
  end

  def onboard_two_save?
    update?
  end

  def onboard_exit?
    update?
  end
end