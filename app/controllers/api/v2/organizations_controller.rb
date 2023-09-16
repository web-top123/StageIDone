class Api::V2::OrganizationsController < Api::V2::BaseController
	
	def user_org
		@user_organizations = @current_user.active_organizations
		render formats: :json
	end
	# GET
	# http://localhost:3000/api/v2/organizations?api_token=db4de0d2886f486f2a2d24e0f5cfed305740eacd&id=awecwrwacwqecw709c6qwcw87r6wcrq
	def show
    @organization = Organization.find_by(hash_id: params[:id])
		@teams = @organization.teams
		@org_team_arr = []
		@teams.each do |team|
			@users = team.users
			@users.each do |user|
				if user.id == @current_user.id
					@org_team_arr << team
				end
			end
		end
	  render formats: :json
	end
end