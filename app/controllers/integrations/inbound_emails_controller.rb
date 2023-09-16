class Integrations::InboundEmailsController < ApplicationController
  skip_after_action :verify_authorized
  protect_from_forgery except: [:create]

  def create
    Rails.logger.info "Received email from #{params[:sender]} (from: #{params[:from]}) to #{params[:recipient]} with token: #{params[:token]} timestamp: #{params[:timestamp]} signature: #{params[:signature]}"
    sender = params[:sender].downcase
    sender.gsub!(/^prvs=(\S*)=/, '') # https://en.wikipedia.org/wiki/Bounce_Address_Tag_Validation

    post_valid = is_valid?(params[:token], params[:timestamp], params[:signature])
    user = User.find_by(email_address: sender) || AlternateEmail.verified_user(sender)
    # if user.nil?
    #   # TODO: Remove this terrible security flaw that allows the setting of a FROM header in a mail message
    #   # to allow an email sender to act as if they are another email user. E.g. cody@idonethis.com could submit
    #   # tasks for teri by telling his email client to use a from name of teri@idonethis.com. 
    #   # It was added to be backwards-compatible with legacy Python app. Should move to additional_addresses field
    #   # of User.
    #   m = Mail::Address.new(params[:from])
    #   user = User.find_by(email_address: m.address.downcase) unless m.address.nil?
    # end
    slug = get_team(params[:recipient])

    if user.nil?
      # Sending to itself will cause an endless loop
      if params[:sender] != "postmaster@entry.idonethis.com"
      	UserMailer.unsuccessful_email_entry(params[:sender], params[:recipient], params['stripped-text']).deliver_now
      end

      Raven.capture_message 'Invalid Email on Inbound Email Integration', extra: { params: params, sender: params[:sender], slug: slug }
      render nothing: true, status: 406 and return
    end

    team = user.active_teams.where(slug: slug).first
    if team.nil? && slug == 'personal'
      team = user.personal_team
    end

    Rails.logger.info "Attempting ingest of email from #{params[:sender]} to #{get_team(params[:recipient])} and valid status: #{post_valid}"
    unless post_valid && user && team && team.active_users.include?(user)
      render nothing: true, status: 406 and return
    end

    date = date_from_subject_or_timestamp(params[:subject], params[:timestamp], user)

    # TODO: Ensure we handle signatures...

    # If there is only one text blob? Is it possible that the user's email
    # client sent multiple entries but separated only by \n
    emailed_entries = MailgunEmailedEntriesPresenter.new(params)
    # Else do the next best thing, and parse the stripped-html
    entries = emailed_entries.parse_stripped_html

    entries.each do |body|
      Entry.create(user: user, team: team, body: body, occurred_on: date, status: 'done', created_by: 'email')
    end

    render nothing: true, status: 200
  end

  private

  def date_from_subject_or_timestamp(subject, timestamp, user)
    month_names = Date::MONTHNAMES.compact # ['January', 'February',...]
    if subject =~ /(#{month_names.join('|')})\s+(\d+), (\d+)/i # Matches for Month DAY, Year
      date = Date.parse("#{$1} #{$2} #{$3}")
      date = date.change(year: date.year - 1) if date.month == 12 && date > 11.months.from_now
      date
    elsif subject =~ /(#{month_names.join('|')})\s+(\d+)/i # Matches for Month DAY
      date = Date.parse("#{$1} #{$2} #{Date.current.year}")  
      date = date.change(year: date.year - 1) if date.month == 12 && date > 11.months.from_now
      date        
    else
      date = Time.at(timestamp.to_i).in_time_zone(user.time_zone).to_date
    end
  end

  def get_team(recipient)
    recipient.split('@')[0].downcase if recipient
  end

  def is_valid?(token, timestamp, signature)
    return false if token.blank? || timestamp.blank? || signature.blank?
    digest = OpenSSL::Digest::SHA256.new
    data = [timestamp, token].join
    signature == OpenSSL::HMAC.hexdigest(digest, Rails.application.config.mailgun[:inbound_email_api_key], data)
  end
end
