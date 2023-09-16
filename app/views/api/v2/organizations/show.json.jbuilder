json.organization @organization
json.team @org_team_arr do |team|
	json.team team
	json.user team.users do |user|
		json.user user
		json.first_latter_name user.full_name_or_something_else_identifying[0]
	end
end