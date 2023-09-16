class SalesforceApi
  def self.create_lead(user)
    client = Restforce.new
    client.create('Lead', lead_params(user))
  end

  def self.lead_params(user)
    #source = lead_source(user)
    {
      Company: 'None', # Company seems required by salesforce?
      Email: user.email_address,
      FirstName: user.first_name,
      LastName: user.last_name.blank? ? 'Unknown' : user.last_name,
      IDT_Admin_Account__c: "ID ##{user.id}",
      LeadSource: lead_source(user),
      Other_Lead_Source__c: '',
      On_IDT2__c: true,
      Trial_Plan_Type__c: '',
      Trial_Start_Date__c: '',
      Phone: user.phone_number || '',
      Time_Zone__c: user.time_zone
    }
  end

  def self.lead_source(user)
    # if the user has sign up via a provider when created we use that as the lead source
    if authentication = user.authentications.first
      "#{authentication.provider.titleize} sign up"
    else
      'direct'
    end
  end

  #def self.lead_source(signup)
  #  str = lead_source_string(signup)
  #  if str.match('adroll')
  #    { lead_source: 'Adroll', other_lead_source: '' }
  #  elsif str.match('adwords')
  #    { lead_source: 'Adwords', other_lead_source: '' }
  #  else
  #    { lead_source: 'Other', other_lead_source: str }
  #  end
  #end

  #def self.lead_source_string(signup)
  #  referrer = [
  #      url_to_display_referrer(signup.first_contact_referrer),
  #      detect_source_from_landing_path(signup.first_contact_landing_path)
  #    ].compact.join(' - ')
  #  source = signup.promo.try(:slug).nil? ? referrer : signup.promo.try(:slug)

  #  source.blank? ? 'direct' : source
  #end

  #def self.detect_source_from_landing_path(path)
  #  return nil unless path

  #  path.include?('?gclid=') ? 'SEM' : nil
  #end

  #def self.url_to_display_referrer(url)
  #  URI.parse(url).host.gsub('www.', '')
  #rescue
  #  nil
  #end
end
