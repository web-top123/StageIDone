class ModifyIntegrationLink < ActiveRecord::Migration
  def change
    remove_column :integration_links, :integration_meta_data
    add_column :integration_links, :meta_data, :text
    add_column :integration_links, :token, :string
  end
end
