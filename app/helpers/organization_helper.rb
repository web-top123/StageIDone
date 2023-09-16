module OrganizationHelper

  def current_active_organization
    last_team_visited = if cookies[:last_team_id].present? && cookies[:last_team_id] == params[:id] ||= params[:team_id]
                          current_user.active_teams.where(hash_id: cookies[:last_team_id]).first
                        end
    if last_team_visited.present?
      last_team_visited&.organization
    elsif params[:id].present?
      Organization.find_by(hash_id: params[:id] ||= params[:organization_id])
    else
      current_user.organizations.last
    end
  end
end
