class EntryMailer < ApplicationMailer
	def assigned_task(sender_user, receiver_user,team,task)
		@sender_user = sender_user
  	@receiver_user = receiver_user
  	@team = team
  	@task = task
  	@today = Time.now.in_time_zone(@receiver_user.time_zone).to_date
  	if @receiver_user.verified?
      @checkin_url = team_url(@team.hash_id)
    else
      @receiver_user.generate_verification_token!
      @checkin_url = team_url(@team.hash_id, v: @receiver_user.verification_token)
    end
    @email_presenter = EmailPresenter.new(@receiver_user.team_memberships.find_by(team: @team))
    mail to: @receiver_user.email_address, subject: "Task assigned to you", from: "I Done This <invitation@idonethis.com>"
  end
end
