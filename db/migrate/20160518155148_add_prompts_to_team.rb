class AddPromptsToTeam < ActiveRecord::Migration
  def change
    add_column :teams, :prompt_done, :text, default: 'What did you get done?'
    add_column :teams, :prompt_goal, :text, default: 'What do you plan to get done?'
    add_column :teams, :prompt_blocked, :text, default: 'What is impeding your progress?'
  end
end
