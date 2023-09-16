class ReminderMailer < ApplicationMailer
  def daily_reminder(team, user)
    @user = user
    @team = team

    @today = Time.now.in_time_zone(@user.time_zone).to_date

    if @user.verified?
      @checkin_url = team_url(@team.hash_id)
    else
      @user.generate_verification_token!
      @checkin_url = team_url(@team.hash_id, v: @user.verification_token)
    end

    @last_sent = if @user.membership_of(@team).email_reminder_last_sent_at.nil?
      @user.membership_of(@team).created_at
    else
      @user.membership_of(@team).email_reminder_last_sent_at
    end

    @last_sent = [Time.current - 7.days, @last_sent].max
    @last_sent_in_english = case @last_sent.to_date
    when Date.yesterday
      'yesterday'
    when Date.current
      'earlier today'
    when Date.current - 7
      'last week'
    else
      @last_sent.strftime('%A')
    end

    @email_presenter = EmailPresenter.new(@user.team_memberships.find_by(team: @team))
    @all_entries = @team.entries.created_since_time(@last_sent)
    @user_entries = @all_entries.where(user_id: @user.id)
    @user_outstanding_goals = @user.entries.outstanding_goals.for_team(@team)
    @flashback = Flashback.get(@user, @team)

    date = @today.strftime("%B %e").gsub(/  /, ' ')
    subject = "#{ team.prompt_for('done') } - #{ team.name } - #{ date }"
    mail to: @user.email_address, subject: subject, from: "I Done This <#{ @team.slug }@entry.idonethis.com>"
  end
end
