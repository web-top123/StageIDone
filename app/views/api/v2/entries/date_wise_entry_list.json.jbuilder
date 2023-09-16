json.current_user @current_user_with_entries do |user|
  if user == @current_user
    json.user user.id
    json.portrait user.portrait
    json.full_name user.full_name
    json.first_latter_name user.full_name_or_something_else_identifying[0]
    json.profile_color user.profile_color
    json.hash_id user.hash_id

    # json.entry user.entries.where(["status = ? and team_id = ? and occurred_on < ? ", "goal",  @team.id, @date]).order('entries.created_at asc') + user.entries.where(["occurred_on = ? and team_id = ?", @date,  @team.id]).order('entries.created_at asc') do |entry|

    if @team.carry_over_goals?
      outstanding_goals = user.entries.for_team(@team).outstanding_goals.chronologically.reject { |g| g.occurred_on >= @date } + user.entries.for_team(@team).outstanding_blocks.chronologically.reject { |g| g.occurred_on >= @date }
    else
      outstanding_goals = Entry.none
    end

    entries = outstanding_goals + user.entries.eager_load(:user, :team, :reactions, :prompting_goal).for_team(@team).for_day(@date).chronologically

    json.entry entries.each do |entry|
      if !entry.completed_same_day?
        json.entry entry
        json.comment_count entry.reactions.where(:reaction_type => "comment").count
        json.reaction entry.reactions do |reaction|
          if reaction.reaction_type == "like"
            json.reaction reaction
            json.user reaction.user.id
            json.portrait reaction.user.portrait
            json.full_name reaction.user.full_name
            json.first_latter_name user.full_name_or_something_else_identifying[0]
            json.profile_color reaction.user.profile_color
            json.hash_id reaction.user.hash_id
          end
        end
      end
    end

  end
end

json.user @users_with_entries do |user|
  if user != @current_user
    json.user user.id
    json.portrait user.portrait
    json.full_name user.full_name
    json.first_latter_name user.full_name_or_something_else_identifying[0]
    json.profile_color user.profile_color
    json.hash_id user.hash_id

    # json.entry user.entries.where(["status = ? and team_id = ? and occurred_on < ? ", "goal",  @team.id, @date]).order('entries.created_at asc') + user.entries.where(["occurred_on = ? and team_id = ?", @date,  @team.id]).order('entries.created_at asc') do |entry|

    if @team.carry_over_goals?
      outstanding_goals = user.entries.for_team(@team).outstanding_goals.chronologically.reject { |g| g.occurred_on >= @date } + user.entries.for_team(@team).outstanding_blocks.chronologically.reject { |g| g.occurred_on >= @date }
    else
      outstanding_goals = Entry.none
    end

    entries = outstanding_goals + user.entries.eager_load(:user, :team, :reactions, :prompting_goal).for_team(@team).for_day(@date).chronologically
    
    json.entry entries.each do |entry|
      if !entry.completed_same_day?
        json.entry entry
        json.comment_count entry.reactions.where(:reaction_type => "comment").count
        json.reaction entry.reactions do |reaction|
          if reaction.reaction_type == "like"
            json.reaction reaction
            json.user reaction.user.id
            json.portrait reaction.user.portrait
            json.full_name reaction.user.full_name
            json.first_latter_name user.full_name_or_something_else_identifying[0]
            json.profile_color reaction.user.profile_color
            json.hash_id reaction.user.hash_id
          end
        end
      end
    end
  end
end

json.users_without_entries @users_without_entries
