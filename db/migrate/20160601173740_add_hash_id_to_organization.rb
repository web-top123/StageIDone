class AddHashIdToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :hash_id, :string, unique: true
    add_index :organizations, :hash_id, unique: true

    Organization.all.each(&:save)
  end
end
