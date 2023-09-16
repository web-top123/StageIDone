class AdminUser < ActiveRecord::Base
  def self.find_or_create_from_oauth(info)
    user = AdminUser.find_by(email_address: info['email'])
    if user.nil?
      user = AdminUser.create(email_address: info['email'], full_name: info['name'])
    end
    user
  end
end
