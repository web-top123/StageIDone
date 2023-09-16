require 'digest/md5'

class AddPortraitToUser < ActiveRecord::Migration
  def change
    add_column :users, :portrait, :string

    User.all.each do |user|
      hash = Digest::MD5.hexdigest(user.email_address)
      user.remote_portrait_url = "http://www.gravatar.com/avatar/#{hash}"
      user.save
    end
  end
end