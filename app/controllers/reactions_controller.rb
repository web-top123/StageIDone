class ReactionsController < ApplicationController
  before_action :require_login

  def show
    reaction = Reaction.find(params[:id])

    authorize reaction

    render partial: 'reactions/comment', locals: {comment: reaction}
  end

  def create
    entry = Entry.find_by_hash_id(params[:entry_id])

    reaction = entry.reactions.new(body: params['comment_body'], reaction_type: 'comment', user: current_user)

    authorize reaction

    reaction.save!

    render partial: 'reactions/comment', locals: {comment: reaction, entry_org: entry.team.organization}
  end

  def edit
    reaction = Reaction.find(params[:id])

    authorize reaction

    render partial: 'reactions/form', locals: {comment: reaction}
  end

  def update
    entry = Entry.find_by_hash_id(params[:entry_id])
    reaction = entry.reactions.find(params[:id])

    authorize reaction

    comment_body = params['comment_body']

    if comment_body.present?
      reaction.update_attributes(body: comment_body)
      render partial: 'reactions/comment', locals: {comment: reaction, entry_org: entry.team.organization}
    else
      reaction.destroy
      render text: ''
    end
  end

  def destroy
    reaction = Reaction.find(params[:id])
    if reaction
      authorize reaction
      reaction.destroy
      render partial: 'reactions/comment', locals: {comment: reaction, entry_org: reaction.reactable.team.organization}
    else
      skip_authorization
    end
  end
end
