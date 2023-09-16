class AddSamlMetaUrlToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :saml_meta_url, :string
  end
end
