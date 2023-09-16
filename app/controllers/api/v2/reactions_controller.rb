class Api::V2::ReactionsController < Api::V2::BaseController

  # POST
  # http://localhost:3000/api/v2/reactions?api_token=dc1c3f51a091278e98cf377b082fcfa36c2066af&entry_id=143f1a044b21c7eb3f21095f6db512c1091a68ce&body=new comment
  def create
    entry = Entry.find_by_hash_id(params[:entry_id])
    team = entry.team
    @reaction = entry.reactions.new(body: params['body'], reaction_type: 'comment', user: @current_user)
    @reaction.save!
    render formats: :json
  end

  # PATCH
  # http://localhost:3000/api/v2/reactions/17?api_token=dc1c3f51a091278e98cf377b082fcfa36c2066af&entry_hash_id=143f1a044b21c7eb3f21095f6db512c1091a68ce&body=new commentASA 1111SASASfoAsr last entry
  def update
    entry = Entry.find_by_hash_id(params[:entry_hash_id])
    @reaction = entry.reactions.find(params[:id])
    comment_body = params['body']
    if comment_body.present?
      @reaction.update_attributes(body: comment_body)
      render formats: :json
    else
      @reaction.destroy
      render json: { success: "Comment has been deleted succsesfully." }, status: 200
    end
  end
end