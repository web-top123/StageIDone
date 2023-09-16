class RecountUsersNextSend < ActiveRecord::Migration
  def change
  	TeamMembership.find_each do |tm|
  	  tm.save
  	end
  end
end
