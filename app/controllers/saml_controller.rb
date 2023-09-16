class SamlController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:consume]
  skip_after_action :verify_authorized
  before_action :require_organization

  def sso
    request = OneLogin::RubySaml::Authrequest.new
    redirect_to(request.create(saml_settings))
  end

  def consume
    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], :settings => saml_settings)

    if response.is_valid?
      @user = @organization.active_users.find_by(email_address: response.nameid)
      if @user.nil?
        # TODO: Generate invitation to redirect to it instead of blank
        #invitation = Invitation.create(organization: @organization, email_address: response.nameid)
        #redirect_to register_path(invitation) and return
        redirect_to register_path and return
      end

      auto_login(@user)
    else
      flash[:alert] = 'Something went wrong and we could not log you in using SSO, please try again later.'
      Rails.logger.error "Invalid SAML SSO Response for Organization ##{@organization.id}. Errors: #{response.errors}"
      Raven.capture_message "Invalid SAML SSO response for organization", extra: { organization_id: @organization.id.to_s, errors: response.errors.inspect }
    end
    redirect_to root_path
  end

  def metadata
    meta = OneLogin::RubySaml::Metadata.new
    render xml: meta.generate(saml_settings), content_type: "application/samlmetadata+xml"
  end

  private

  def require_organization
    @organization = Organization.find_by(hash_id: params[:id])
    if @organization.nil? || @organization.saml_meta_url.blank?
      render text: 'SAML SSO is not configured for this organization. Ask an organization administrator to set this up and try again.'
    end
  end

  def saml_settings
    idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
    # Returns OneLogin::RubySaml::Settings prepopulated with idp metadata
    settings = idp_metadata_parser.parse_remote(@organization.saml_meta_url)

    settings.assertion_consumer_service_url = "#{request.protocol}#{request.host_with_port}/saml/consume/#{@organization.hash_id}"
    settings.issuer                         = "#{request.protocol}#{request.host_with_port}/saml/metadata/#{@organization.hash_id}"
    settings.name_identifier_format         = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

    settings
  end
end
