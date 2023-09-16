json.array! @teams do |team|
	if team.name == "Personal progress log"
		json.id team.id
		json.hash_id team.hash_id
		json.name team.name
		json.created_at team.created_at
		json.updated_at team.updated_at

		json.organization team.organization

		json.user team.team_memberships.active do |tm|
			user = User.find(tm.user_id)
			json.user user
			json.first_latter_name user.full_name_or_something_else_identifying[0]
		end
	end
end

json.array! @teams do |team|
	if team.name != "Personal progress log"
		if team.organization.present?
			if team.organization.stripe_subscription_status == "trialing" || team.organization.stripe_subscription_status == "active"
				json.id team.id
				json.hash_id team.hash_id
				json.name team.name
				json.created_at team.created_at
				json.updated_at team.updated_at

				json.organization team.organization
				json.stripe_subscription_status "active"
				json.user team.team_memberships.active do |tm|
					user = User.find(tm.user_id)
					json.user user
					json.first_latter_name user.full_name_or_something_else_identifying[0]
				end
			else
				json.id team.id
				json.hash_id team.hash_id
				json.name team.name
				json.created_at team.created_at
				json.updated_at team.updated_at

				json.organization team.organization
				json.stripe_subscription_status "inactive"
				json.user team.team_memberships.active do |tm|
					user = User.find(tm.user_id)
					json.user user
					json.first_latter_name user.full_name_or_something_else_identifying[0]
				end
			end
		else
			json.id team.id
			json.hash_id team.hash_id
			json.name team.name
			json.created_at team.created_at
			json.updated_at team.updated_at

			json.organization team.organization
			"No organization."
			json.user team.team_memberships.active do |tm|
				user = User.find(tm.user_id)
				json.user user
				json.first_latter_name user.full_name_or_something_else_identifying[0]
			end
		end
	end
end