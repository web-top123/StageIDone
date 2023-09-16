class ChangeDefaultForUserTimeZone < ActiveRecord::Migration
  def change
    change_column_default(:users, :time_zone, 'Pacific Time (US & Canada)')
  end
end
