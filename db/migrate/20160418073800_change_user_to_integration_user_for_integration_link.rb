class ChangeUserToIntegrationUserForIntegrationLink < ActiveRecord::Migration
  def change
    remove_column :integration_links, :integration_user_id
    add_reference :integration_links, :integration_user, index: true
    remove_column :integration_links, :user_id
  end
end
