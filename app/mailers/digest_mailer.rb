class DigestMailer < ApplicationMailer
  def daily_digest(team_membership)
    @user = team_membership.user
    @team = team_membership.team

    # generate the digest for the user's timezone
    Time.use_zone(@user.time_zone) do
      if @user.verified?
        @team_url = team_url(@team.hash_id)
      else
        @user.generate_verification_token!
        @team_url = team_url(@team.hash_id, v: @user.verification_token)
      end

      @last_sent = if team_membership.email_digest_last_sent_at.nil?
        team_membership.created_at
      else
        team_membership.email_digest_last_sent_at
      end
      # Limit the period to the last week, if for some reason last sent is very long ago
      @last_sent = [Time.current - 7.days, @last_sent].max

      @entries = @team.entries.created_since_time(@last_sent)

      @email_presenter = EmailPresenter.new(@user.team_memberships.find_by(team: @team))

      @today = Date.current

      team_members = @team.members_at(@today)
      @users_with_entries = team_members.where(id: @entries.pluck(:user_id).uniq).alphabetically
      @users_without_entries = team_members - @users_with_entries
      date = @today.strftime("%B %e").gsub(/  /, ' ')
      mail to: @user.email_address, subject: "#{ @team.name } Digest for #{ date }", from: "I Done This <#{ @team.slug }@entry.idonethis.com>"
    end
  end
end
