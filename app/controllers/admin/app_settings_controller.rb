class Admin::AppSettingsController < Admin::ApplicationController
  def show
    @app_setting = AppSetting.current
  end

  def update
    @app_setting = AppSetting.current
    if @app_setting.update_attributes(app_setting_params)
      redirect_to [:admin, :app_settings]
    else
      render 'show'
    end
  end

  private

  def app_setting_params
    params.require(:app_setting).permit(
      :tiny_monthly_plan_id,
      :tiny_monthly_plan_price_in_cents,
      :tiny_yearly_plan_id,
      :tiny_yearly_plan_price_in_cents,
      :basic_monthly_plan_id,
      :basic_monthly_plan_price_in_cents,
      :basic_yearly_plan_id,
      :basic_yearly_plan_price_in_cents,
      :small_monthly_plan_id,
      :small_monthly_plan_price_in_cents,
      :small_yearly_plan_id,
      :small_yearly_plan_price_in_cents,
      :medium_monthly_plan_id,
      :medium_monthly_plan_price_in_cents,
      :medium_yearly_plan_id,
      :medium_yearly_plan_price_in_cents,
      :large_monthly_plan_id,
      :large_monthly_plan_price_in_cents,
      :large_yearly_plan_id,
      :large_yearly_plan_price_in_cents,
      :invoice_monthly_plan_id,
      :invoice_monthly_plan_price_in_cents,
      :invoice_yearly_plan_id,
      :invoice_yearly_plan_price_in_cents
    )
  end
end