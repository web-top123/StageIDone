class NotificationMailer < ApplicationMailer
  def comment_notification(comment)
    unless comment.present? && comment.reactable.present? &&
           comment.reactable.user.present?
      Raven.capture_message "Not sending comment notification because of missing requirements", extra: { comment: comment.inspect }
      return
    end

    @comment = comment
    @team = comment.reactable.team
    @commenter = @comment.user
    @entry = @comment.reactable
    @enterer = @comment.reactable.user

    if @enterer.verified?
      @comment_page_url =  team_url(@team.hash_id, date: @entry.occurred_on)
    else
      @enterer.generate_verification_token!
      @comment_page_url = team_url(@team.hash_id, date: @entry.occurred_on, v: @enterer.verification_token)
    end

    unless @enterer.present?
      Raven.capture_message "Not sending comment notification because enterer is absent", extra: { comment: comment.inspect }
      return
    end

    unless @enterer.membership_of(@team).present?
      Raven.capture_message "Not sending comment notification because enterer is not a member of the team", extra: { comment: comment.inspect }
      return
    end

    unless @enterer.membership_of(@team).subscribed_notifications.include?('comment')
      Raven.capture_message "Not sending comment notifications because enterer is not subscribed", extra: { comment: comment.inspect }
      return
    end

    @email_presenter = EmailPresenter.new(@enterer.team_memberships.find_by(team: @team))

    mail to: @enterer.email_address, subject: "New comment on your entry", from: "#{ @commenter.full_name_or_something_else_identifying } <support@idonethis.com>"
  end

  def mention_notification(mention)
    unless mention.present? && mention.mentionable.present? && mention.user.present?
      Raven.capture_message "Not sending mention notification because of missing requirements", extra: { mention: mention.inspect }
      return
    end

    @mention = mention
    @mentionable = @mention.mentionable
    @mentioner = @mentionable.user
    @team = @mentionable.team

    if @mention.mentionable_type == 'Entry'
      @entry  = @mentionable
      @subject = "Mentioned in an Entry"
    else
      @entry  = @mentionable.reactable
      @subject = "Mentioned in a #{ @mention.mentionable_type }"
    end

    @mentionee = @mention.user

    if @mentionee.verified?
      @mention_page_url =  team_url(@team.hash_id, date: @entry.occurred_on)
    else
      @mentionee.generate_verification_token!
      @mention_page_url =  team_url(@team.hash_id, date: @entry.occurred_on, v: @mentionee.verification_token)
    end

    unless @mentionee.present?
      Raven.capture_message "Not sending mention notification because mentionee is absent", extra: { mention: mention.inspect }
      return
    end

    unless @mentionee.membership_of(@team).present?
      Raven.capture_message "Not sending comment notifications because mentionee is not a member of the team", extra: { mention: mention.inspect }
      return
    end

    unless @mentionee.membership_of(@team).subscribed_notifications.include?('mention')
      Raven.capture_message "Not sending mention notifications because mentionee is not subscribed", extra: { mention: mention.inspect }
      return
    end

    @email_presenter = EmailPresenter.new(@mention.user.team_memberships.find_by(team: @team))

    mail to: @mentionee.email_address, subject: @subject, from: "#{ @mentioner.full_name_or_something_else_identifying } <support@idonethis.com>"
  end
end
