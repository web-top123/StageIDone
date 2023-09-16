class AlternateEmailsController < ApplicationController
  before_action :require_login, except: [:verify]

  def create
    @alternate_email = current_user.alternate_emails.new(alternate_email_params)

    authorize @alternate_email

    if @alternate_email.save
      render partial: 'list'
    else
      render partial: 'form', locals: { alternate_email: @alternate_email }, status: 422
    end
  end

  def destroy
    @alternate_email = current_user.alternate_emails.find(params[:id])

    authorize @alternate_email

    @alternate_email.destroy
    render partial: 'list'
  end

  def verify
    @alternate_email = AlternateEmail.find_by(verification_code: params[:verification_code])
  
    authorize :alternate_email

    if @alternate_email.present?
      @alternate_email.verify!
      redirect_to settings_user_url, notice: 'Alternate email verified.'
    else
      redirect_to settings_user_url, notice: 'Alternate email already verified.'
    end
  end

  private
    def alternate_email_params
      params.require(:alternate_email).permit(:email_address)
    end
end
