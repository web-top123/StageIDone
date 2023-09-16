class TagsController < ApplicationController
  before_action :require_login

  def show
    if params[:team_id]
      @team = Team.find_by(hash_id: params[:team_id])
      authorize @team, :tag?

      # @tag = @team.tags.find_by(name: params[:id].downcase)
      @tag = @team.tags.includes(:entries).find_by(name: params[:id].downcase)
      raise ActionController::RoutingError.new('Not Found') if @tag.nil?
      @entries = @tag.entries.for_team(@team).order('occurred_on desc').page(params[:page]).per(10)
      # @entries = @tag.entries.for_team(@team).order('occurred_on desc')
      render 'team'
      return
    elsif params[:comment_id]
      @organization = current_user.active_organizations.find_by(hash_id: params[:organization_id])
      @reaction = Reaction.find(params[:comment_id])
      o_entries = @organization.entries
      @reactions_arr = []
      o_entries.each do |r|
        if r.reactions.present?
          r.reactions.each do |rr|
            @reactions_arr << rr
          end
        end
      end
      @reactions = Reaction.where(id: @reactions_arr.map(&:id))
      authorize @organization, :tag?
      # @tag = @organization.tags.find_by(name: params[:id].downcase)
      
      # @tag = @organization.tags.includes(:entries).find_by(name: params[:id].downcase)
      @tag = @reaction.tags.find_by(name: params[:id].downcase)

      # @entries = Reaction.all.where("body LIKE ?", "#{'#'+@tag.name}%")
      raise ActionController::RoutingError.new('Not Found') if @tag.nil?
      
      @entries = @tag.entries.for_organization(@organization).order('occurred_on desc').page(params[:page]).per(10)
      @reactions = @tag.reactions.order('created_at desc').page(params[:page]).per(10)
      # @entries_l = Entry.where(id: @entries_arr.map(&:id))
      # @reactions_l = Reaction.where(id: @reactions_arr.map(&:id))
      # @entries = @entries_l + @reactions_l
      # @entries =  @entries
      # @reactions_all =  @tag.reactions
      # @entries = @tag.entries.for_organization(@organization).order('occurred_on desc')
      # @entries = Reaction.all.where("body LIKE ?", "#{'#'+@tag.name}%")
      render 'organization'
      return
    else
      @organization = current_user.active_organizations.find_by(hash_id: params[:organization_id])
      authorize @organization, :tag?
      # @tag = @organization.tags.find_by(name: params[:id].downcase)
      @tag = @organization.tags.includes(:entries).find_by(name: params[:id].downcase)
      raise ActionController::RoutingError.new('Not Found') if @tag.nil?
      @entries = @tag.entries.for_organization(@organization).order('occurred_on desc').page(params[:page]).per(10)
      # @entries = @tag.entries.for_organization(@organization).order('occurred_on desc')
      render 'organization'
      return
    end
  end
end