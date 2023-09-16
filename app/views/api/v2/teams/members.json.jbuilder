# @team.users.each do |user|
#   json.user do
#     json.(user, :email_address, :full_name, :portrait, :hash_id )
#   end
# end

json.array!(@members) do |person|
  json.id person.id	
  json.email_address person.email_address
  json.full_name person.full_name
  json.portrait person.portrait
  json.profile_color person.profile_color
  json.first_latter_name person.full_name_or_something_else_identifying[0]
  json.hash_id person.hash_id
end