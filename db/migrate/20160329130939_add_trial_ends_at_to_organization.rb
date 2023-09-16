class AddTrialEndsAtToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :trial_ends_at, :datetime

    Organization.all.each(&:save)
  end
end
