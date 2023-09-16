class Api::V2::EntriesController < Api::V2::BaseController
  before_filter :find_entry, except: [:index, :show,:create ,:assign,:date_wise_entry_list,:toggle_like]
 
  # GET
  # http://localhost:3000/api/v2/entries?api_token=dc1c3f51a091278e98cf377b082fcfa36c2066af&team_hash_id=2bc8ab91ac4b

#  Comment by Anurag
# def index 
#    if params[:team_hash_id] && team = Team.find_by(hash_id: params[:team_hash_id])
#      if params[:user_hash_id] && user = User.find_by(hash_id: params[:user_hash_id])
#        entries = user.entries.eager_load(:team).where(team: team).order('entries.created_at desc')
#      end
#    end
#    paginate json: entries.map{|e| e.pretty_format}
#  end
# End of Comment by Anurag

# Copied from Github from the release 15 May 2018 done on 9th Feb 2021 for Zapier Integration
  def index
    if params[:team_id] && team = Team.find_by(hash_id: params[:team_id])
      entries = @current_user.entries.eager_load(:team).where(team: team).order('entries.created_at desc')
    end
    paginate json: entries.map{|e| e.pretty_format}
  end
# End of Copy by Anurag
  
  # GET
  # http://localhost:3000/api/v2/entries/date_wise_entry_list?api_token=71ed2f43de02e862c99746ae51235d6325ecc3bc&date=2018-05-23&team_hash_id=a0042d3852c9
  def date_wise_entry_list
    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    if params[:team_hash_id] && @team = Team.find_by(hash_id: params[:team_hash_id])
      users = @team.members_at(@date).alphabetically
      @current_user_with_entries = users.uniq.joins(:entries).
        where(entries: { team_id: @team.id}).
        reject{|u| u != @current_user}

      @users_with_entries = users.uniq.joins(:entries).
        where(entries: { team_id: @team.id}).
        reject{|u| u == @current_user}
      arr = []
      @users_with_entries.each do |user|
        entries_blocked = user.entries.blockers.for_team(@team).where('occurred_on <= ?', @date)
        entries_done = user.entries.dones.for_team(@team).where('occurred_on = ?', @date)
        entries_goal = user.entries.goals.where(completed_on: nil).where(archived_at: nil).for_team(@team).where('occurred_on <= ?', @date)
        entries_goal_complited = entries_goal.where.not(completed_on: nil).for_team(@team)

        logger.info("--Userrrr Email Address>>>>>>--#{user.email_address.inspect}----")
        logger.info("--Entries_blocked>>>>>>>>>>>>--#{entries_blocked.inspect}-------")
        logger.info("--Entries_goal>>>>>>>>>>>>>>>--#{entries_goal.inspect}----------")
        logger.info("--Entries_done>>>>>>>>>>>>>>>--#{entries_done.inspect}----------")
        logger.info("--Etr_goal_complited>>>>>>>--#{entries_goal_complited.inspect}--")

        if !entries_blocked.any? && !entries_done.any? && !entries_goal.any? && entries_goal_complited.any?
          arr << user
        elsif !entries_blocked.any?
          if !entries_done.any?
            if !entries_goal.any?
              arr << user
            end
          end
        elsif !entries_done.any?
          if !entries_blocked.any?
            if !entries_goal.any?
              arr << user
            end
          end
        elsif !entries_goal.any?
          if !entries_blocked.any?
            if !entries_done.any?
              arr << user
            end
          end
        end
      end
      @users_with_entries.delete(arr)
      c = @users_with_entries.reject{ |e| arr.include? e }
      @users_with_entries = c
      @users_without_entries = users.reject{|u| u == @current_user} - @users_with_entries
    end 
    render formats: :json
  end 
 
  # POST
  # http://localhost:3000/api/v2/entries?api_token=71ed2f43de02e862c99746ae51235d6325ecc3bc&team_id=a0042d3852c9&occurred_on=2018-05-23&status=done
  # body = "entry #text"
  def create
    @team = Team.find_by(hash_id: create_entry_params[:team_id])
    unless @team.active_users.include?(@current_user)
      error!('You do not have access to that team', 401) and return
    end
    # Do this to make the default status done, if not provided
    entry_params = {created_by: 'api', status: 'done', occurred_on: Date.current}.
      merge(create_entry_params.except(:team_id)).
      merge(team: @team)
    entry = @current_user.entries.build(entry_params)
    if entry.save
      render json: entry.pretty_format
    else
      error!(entry.errors.full_messages.join(' '), 400)
    end
  end

  # GET
  # http://localhost:3000/api/v2/entries/0d0648ae10b458b7480adbea988f130affc25da1?api_token=71ed2f43de02e862c99746ae51235d6325ecc3bc
  def show
    @entry = Entry.find_by(hash_id: params[:id])
    @comments = @entry.reactions.where(:reaction_type => "comment")
    render formats: :json
    # render json: @entry.pretty_format
  end

  # POST
  # http://localhost:3000/api/v2/entries/298d58fe43961fe1ebf931a81a061dba0fc24086?api_token=1aee884dd8297e45091a0ffff27c80142373b8f1&team_id=ec63d4896df9&body=new_task
  def update
    if update_entry_params[:team_id]
      @team = Team.find_by(hash_id: update_entry_params[:team_id])
      unless @team.active_users.include?(@current_user)
        error!('You do not have access to that team', 401) and return
      end
    end
    attrs = update_entry_params.except(:team_id)
    attrs.merge!(team: @team) if @team
    if @entry.update_attributes(attrs)
      render json: @entry.pretty_format
    else
      error!(entry.errors.full_messages.join(' '), 400)
    end
  end

  # destroy
  # http://localhost:3000/api/v2/entries/575e9a8537f503ca1a280b219eab6f695577edff?api_token=dc1c3f51a091278e98cf377b082fcfa36c2066af
  def destroy
    if @entry.destroy # FIXME: Don't actually destroy, just hide
      render json: {deleted: true, hash_id: @entry.hash_id}
    else
      error!(entry.errors.full_messages.join(' '), 400)
    end
  end

  # GET
  #  http://localhost:3000/api/v2/entries/74750b466692ce6be21c5d133b46cdce15f10a24/assign?api_token=dc1c3f51a091278e98cf377b082fcfa36c2066af&user_id=1
  def assign
    entry = Entry.find_by_hash_id(params[:id])
    # authorize entry
    @user = User.find(params[:user_id])
    if @user.present? && @user != @current_user
      entry.user_id = params[:user_id]
      entry.save
    end
    render json: { success: "task assigned succsesfully." }, status: 200
    # error!('task assined succsesfully.', 200) and return
  end

  # POST
  # http://localhost:3000//api/v2/entries/0d0648ae10b458b7480adbea988f130affc25da1/toggle_like?api_token=71ed2f43de02e862c99746ae51235d6325ecc3bc
  def toggle_like
    entry = Entry.find_by_hash_id(params[:id])
    @team_members = entry.team.users
    reaction = Reaction.is_like.where(reactable: entry, user: @current_user).first
    if reaction
      reaction.destroy!
      render json: { success: "You disliked task succsesfully" }, status: 200
    else
      Reaction.create! reactable: entry, reaction_type: 'like', user: @current_user
      render json: { success: "You liked task succsesfully" }, status: 200
    end
  end

  # POST
  # http://localhost:3000//api/v2/entries/ebb3043e55681207c449515c3adac26b00dfa568/mark_done?api_token
  def mark_done
    entry = Entry.find_by(hash_id: params[:id])
    entry.mark_done!(Date.current)
    render json: { success: "Mark as done." }, status: 200
  end

  private

  def create_entry_params
    params.require(:body)
    params.require(:team_id)
    params.permit(:body, :team_id, :occurred_on, :status)
  end

  def update_entry_params
    params.permit(:body, :team_id, :occurred_on, :status)
  end

  def find_entry
    # Use find_by to return nil instead of exception
    @entry = Entry.find_by(hash_id: params[:id])
    unless @entry && @entry.user == @current_user
      error!('You do not have access to that entry', 401) and return
    end
  end
end
