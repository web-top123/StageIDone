json.entry @entry
json.reaction @entry.reactions do |reaction|
  if reaction.reaction_type == "comment"
    json.reaction reaction
    json.user reaction.user.id
    json.portrait reaction.user.portrait
    json.full_name reaction.user.full_name
    json.first_latter_name reaction.user.full_name_or_something_else_identifying[0]
    json.profile_color reaction.user.profile_color
    json.hash_id reaction.user.hash_id
  end
end