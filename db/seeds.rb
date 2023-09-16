if Rails.env.development?
  AdminUser.delete_all
  IntercomQueue.delete_all
  Entry.delete_all
  EntryTag.delete_all
  Hook.delete_all
  IntegrationLink.delete_all
  IntegrationUser.delete_all
  Invitation.delete_all
  Mention.delete_all
  OrganizationMembership.with_deleted.delete_all
  Organization.delete_all
  Reaction.delete_all
  Tag.delete_all
  TeamMembership.with_deleted.delete_all
  Team.delete_all
  User.with_deleted.delete_all
  ArchivedNotification.delete_all
  Notification.delete_all

  3.times do
    org = Organization.create(name: "#{ Faker::Company.name } #{ Faker::Company.suffix }")

    puts "Created organization: #{ org.name }"

    3.times do
      team = Team.create(name: "#{ Faker::Company.profession.capitalize }s", organization: org, public: [true, false].sample)

      puts "Created team: #{ team.name }"
    end

    org.reload

    (10..20).to_a.sample.times do
      user = User.create!(email_address: Faker::Internet.email, full_name: Faker::Name.name, show_personal_team: false, last_seen_at: (Time.zone.now - (1..30).to_a.sample.days), password: 'password123')
      puts "Created user: #{ user.full_name }"

      2.times do
        TeamMembership.create(user: user, team: org.teams.to_a.sample, subscribed_notifications: ['like','mention','comment'])
      end

      OrganizationMembership.create!(user: user, organization: org, role: %w(owner admin member).sample)

      user.reload

      (20..40).to_a.sample.times do
        print "."
        Entry.create!(body: Faker::Lorem.paragraph, user: user, team: user.teams.to_a.sample, status: %w(done goal blocked).sample, occurred_on: (Date.current - (0..14).to_a.sample), created_by: 'faker')
      end
    end

    org.reload

    (100 + (0..100).to_a.sample).times do
      print "-"
      if [true,false,false].sample
        Reaction.create! user: org.users.to_a.sample, reactable: org.entries.to_a.sample, body: Faker::Lorem.sentence, reaction_type: 'comment'
      else
        Reaction.create! user: org.users.to_a.sample, reactable: org.entries.to_a.sample, body: nil, reaction_type: 'like'
      end
    end
  end

  commenter = User.create! email_address: "commenterGuy@idonethis.com", full_name: "Mister Commenter", show_personal_team: false, password: 'password123'
  poster = User.create! email_address: "posterGuy@idonethis.com", full_name: "Mister Poster", show_personal_team: false, password: 'password123'
  
  u = User.create! email_address: "teri@idonethis.com", full_name: "Teri Wilson", show_personal_team: false, password: 'password123'



  Organization.all.each do |o|
    OrganizationMembership.create! user: u, organization: o, role: 'owner'
    OrganizationMembership.create! user: commenter, organization: o, role: 'owner'
    OrganizationMembership.create! user: poster, organization: o, role: 'owner'

    o.teams.each do |t|
      TeamMembership.create! team: t, user: u, subscribed_notifications: ['like','mention','comment']
      TeamMembership.create! team: t, user: commenter, subscribed_notifications: ['like','mention','comment']
      TeamMembership.create! team: t, user: poster, subscribed_notifications: ['like','mention','comment']
    end
  end

  (10).times do
    Entry.create!(body: Faker::Lorem.paragraph, user: u, team: u.teams.to_a.sample, status: %w(done goal blocked).sample, occurred_on: Date.current + (0..2).to_a.sample.days, created_by: 'faker')
  end

  (10).times do
    Entry.create!(body: '@teri ' + Faker::Lorem.paragraph, user: poster, team: u.teams.to_a.sample, status: %w(done goal blocked).sample, occurred_on: Date.current + (0..2).to_a.sample.days, created_by: 'faker')
  end

  u.entries.each do |e|
    if [true,false].sample
      Reaction.create! user: commenter, reactable: u.entries.to_a.sample, body: "@teri, #{Faker::Lorem.sentence}", reaction_type: 'comment'
    else
      Reaction.create! user: commenter, reactable: u.entries.to_a.sample, body: nil, reaction_type: 'like'
    end
  end
end
