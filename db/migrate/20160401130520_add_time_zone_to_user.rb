class AddTimeZoneToUser < ActiveRecord::Migration
  def change
    add_column :users, :time_zone, :string, default: 'America/Los_Angeles'
  end
end
