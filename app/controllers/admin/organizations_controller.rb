class Admin::OrganizationsController < Admin::ApplicationController
  def index
    if params[:filter_field].present? &&
       (params[:filter_field].downcase != 'all') &&
       Organization.filter_fields.include?(params[:filter_field].downcase)

      @organizations = Organization.alphabetically.advanced_search(params[:filter_field].to_sym => params[:filter_value]).page(params[:page])
      @scope_count = Organization.alphabetically.advanced_search(params[:filter_field].to_sym => params[:filter_value]).size
      @filter_params = params.slice(:filter_field, :filter_value)

      if @organizations.size == 1
        redirect_to [:admin, @organizations.first]
        return
      end
    else
      @scope_count = Organization.alphabetically.count
      @organizations = Organization.alphabetically.page(params[:page])
    end
  end

  def show
    @filter_params = params.slice(:filter_field, :filter_value)
    @organization = Organization.find_by(hash_id: params[:id])
  end

  def update
    @organization = Organization.find_by(hash_id: params[:id])
    @organization.update_attributes(organization_params)
    redirect_to [:admin, @organization]
  end

  def destroy
    @organization = Organization.find_by(hash_id: params[:id])
    @organization.destroy
    redirect_to [:admin, :organizations], notice: "#{@organization.name} deleted"
  end

  private

  def organization_params
    params.require(:organization).permit(
      :name,
      :saml_meta_url,
      :trial_ends_at
    )
  end
end