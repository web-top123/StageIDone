class AddAutorToNotification < ActiveRecord::Migration
  def change
    add_reference :notifications, :author, null: false
  end
end
