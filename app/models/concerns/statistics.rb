module Statistics
  extend ActiveSupport::Concern

  def most_active_users_in_period(start_date, end_date)
    # a like is worth half of a comment, a comment is worth a quarter of an entry
    users.select("users.full_name,
                  users.hash_id,
                  users.profile_color,
                  users.go_by_name,
                  users.nickname,
                  users.email_address,
                  count(entries.id) as entry_count,
                  count(comments.id) as comment_count,
                  count(likes.id) as like_count,
                  (count(entries.id) + (count(comments.id) * 0.25) + (count(likes.id) * 0.125)) as user_ranking
                 ")
         .joins(:entries)
         .where("entries.occurred_on >= ? and entries.occurred_on <= ?", start_date, end_date)
         .joins("LEFT JOIN reactions as comments ON comments.reactable_id = entries.id
                 AND comments.reaction_type = 'comment'
                 AND (comments.created_at >= '#{start_date}' AND comments.created_at <= '#{end_date}')")
         .joins("LEFT JOIN reactions as likes ON likes.reactable_id = entries.id
                 AND likes.reaction_type = 'like'
                 AND (likes.created_at >= '#{start_date}' AND likes.created_at <= '#{end_date}')")
         .group("users.full_name,
                 users.hash_id,
                 users.profile_color,
                 users.go_by_name,
                 users.nickname,
                 users.email_address")
         .order("user_ranking desc")
  end

  def wof_dreamer_for_period(start_date, end_date)
    users.select("users.full_name,
                  users.hash_id,
                  users.profile_color,
                  users.go_by_name,
                  users.nickname,
                  users.email_address,
                  count(entries.id) as entry_count
                 ")
         .joins("LEFT JOIN entries ON entries.user_id = users.id
                 AND entries.occurred_on >= '#{start_date}' and entries.occurred_on <= '#{end_date}'
                 AND entries.status = 'goal'")
         .group("users.full_name,
                 users.hash_id,
                 users.profile_color,
                 users.go_by_name,
                 users.nickname,
                 users.email_address")
         .order("entry_count desc")
         .first
  end

  def wof_loquacious_for_period(start_date, end_date)
    users.select("users.full_name,
                  users.hash_id,
                  users.profile_color,
                  users.go_by_name,
                  users.nickname,
                  users.email_address,
                  sum(coalesce(character_length(entries.body), '0')) as entry_length
                 ")
         .joins("LEFT JOIN entries ON entries.user_id = users.id
                 AND entries.occurred_on >= '#{start_date}' and entries.occurred_on <= '#{end_date}'")
         .group("users.full_name,
                 users.hash_id,
                 users.profile_color,
                 users.go_by_name,
                 users.nickname,
                 users.email_address")
         .order("entry_length desc")
         .first
  end

  def wof_busiest_for_period(start_date, end_date)
    users.select("users.full_name,
                  users.hash_id,
                  users.profile_color,
                  users.go_by_name,
                  users.nickname,
                  users.email_address,
                  count(entries.id) as entry_count
                 ")
         .joins("LEFT JOIN entries ON entries.user_id = users.id
                 AND entries.occurred_on >= '#{start_date}' and entries.occurred_on <= '#{end_date}'
                 AND entries.status = 'done'")
         .group("users.full_name,
                 users.hash_id,
                 users.profile_color,
                 users.go_by_name,
                 users.nickname,
                 users.email_address")
         .order("entry_count desc")
         .first
  end
end