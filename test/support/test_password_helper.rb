require "bcrypt"

module TestPasswordHelper
  def default_password_digest
    "$2a$10$kEUbrU31ml9Uap8L1NMBK.eCe7BTicZZr5wux9zxejEMOGS8mlpuy"
  end

  def default_password
    "password"
  end
end
