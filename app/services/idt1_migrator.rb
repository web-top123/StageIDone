require 'htmlentities'
require 'tz_map'
class Idt1Migrator
  IDT1_DB = Sequel.connect(ENV['IDT1_DB_URL'])
  IDT1_PROD_DB = Sequel.connect(ENV['IDT1_PROD_DB_URL'])

  def self.org_and_teams(username)
    return nil, nil, nil if username.nil?
    @users                 = IDT1_DB[:accounts_user]
    @organizations         = IDT1_DB[:main_organization]
    @organization_profiles = IDT1_DB[:main_organizationprofile]
    @teams                 = IDT1_DB[:main_team]
    @team_profiles         = IDT1_DB[:main_teamprofile]

    matches = @users.where(username: username)
    return nil, nil, nil if matches.blank?
    @user = matches.first
    @org_profile = @organization_profiles.where(user_id: @user[:id]).first
    @org = @organizations.where(id: @org_profile[:organization_id], active: true).first if @org_profile

    @tps = @team_profiles.where(user_id: @user[:id]).all
    @teams = @teams.where(id: @tps.map{|tp| tp[:team_id]}, active: true).all if @tps

    return @user, @org, @teams
  end

  def self.migrate(source_data, disable_digest_and_reminders=false, override=false)
    # maps from old ids to new ids
    user_transforms = {}
    org_transforms = {}
    team_transforms = {}
    entry_transforms = {}
    tag_transforms = {}

    migrated_data = {
      users:                    Set.new,
      organizations:            Set.new,
      organization_memberships: Set.new,
      teams:                    Set.new,
      team_memberships:         Set.new,
      entries:                  Set.new,
      reactions:                Set.new,
      tags:                     Set.new,
      entry_tags:               Set.new
    }

    ActiveRecord::Base.transaction do
      puts "Inserting users"
      source_data[:users].each do |idt1_user|
        idt2_user = transform_user(idt1_user)
        u = User.new(idt2_user)
        u.save(validate: false)
        idt2_user_id = u.id
        user_transforms[idt1_user[:id]] = idt2_user_id
        idt2_user[:id] = idt2_user_id
        migrated_data[:users].add idt2_user
      end

      puts "Inserting orgs"
      source_data[:organizations].each do |idt1_org|
        idt2_org = transform_organization(idt1_org)
        o = Organization.new(idt2_org)
        o.is_migrating = true
        o.save
        update_stripe_subscription_status(o)
        idt2_org_id = o.id
        org_transforms[idt1_org[:id]] = idt2_org_id
        idt2_org[:id] = idt2_org_id
        migrated_data[:organizations].add idt2_org
      end

      puts "Inserting org profiles"
      source_data[:organization_profiles].each do |idt1_profile|
        idt2_profile = transform_org_profile(user_transforms, org_transforms, idt1_profile)
        om = OrganizationMembership.new(idt2_profile)
        om.skip_quantity_update = true
        om.save
        idt2_profile_id = om.id
        idt2_profile[:id] = idt2_profile_id
        migrated_data[:organization_memberships].add idt2_profile
      end

      puts "Inserting teams"
      source_data[:teams].each do |idt1_team|
        new_org = nil
        if idt1_team[:type] == 'TEAM' && idt1_team[:organization_id].nil?  # This team has no org
          new_org = Organization.new(name: idt1_team[:name])
          new_org.is_migrating = true
          team_type = IDT1_DB[:django_content_type].where(model: 'team').first[:id]
          bs = IDT1_DB[:main_billingsubscription].where(billable_content_type_id: team_type, billable_object_id: idt1_team[:id]).first
          if bs
            bc = IDT1_DB[:main_billingcustomer].where(id: bs[:billing_customer_id]).first
            if bc
              new_org.stripe_customer_token = bc[:stripe_customer_id]
              new_org.trial_ends_at = bc[:created] + 14.days
            end
          end
          new_org.save
          update_stripe_subscription_status(new_org)

          source_data[:team_profiles].each do |idt1_profile|
            if idt1_profile[:team_id] == idt1_team[:id]
              om = OrganizationMembership.new(
                user_id: user_transforms[idt1_profile[:user_id]],
                organization_id: new_org.id,
                role: (idt1_profile[:is_admin] ? 'owner' : 'member')
              )
              om.skip_quantity_update = true
              om.save
            end
          end
        end
        idt2_team = transform_team(org_transforms, idt1_team, new_org)
        idt2_team_id = Team.create(idt2_team).id
        team_transforms[idt1_team[:id]] = idt2_team_id
        idt2_team[:id] = idt2_team_id
        migrated_data[:teams].add idt2_team
      end

      puts "Inserting team profiles"
      source_data[:team_profiles].each do |idt1_profile|
        source_team = find_source_team(source_data[:teams], idt1_profile[:team_id])
        idt2_profile = transform_team_profile(user_transforms, team_transforms, idt1_profile, disable_digest_and_reminders)
        idt2_profile_id = TeamMembership.create(idt2_profile).id
        idt2_profile[:id] = idt2_profile_id
        if source_team[:type] == 'PERSONAL'
          personal_user = User.find(user_transforms[idt1_profile[:user_id]])
          personal_user.show_personal_team = true
          personal_user.save(validate: false)
        end
        migrated_data[:team_memberships].add idt2_profile
      end

      puts "Inserting entries"
      source_data[:entries].each do |idt1_entry|
        idt2_entry = transform_entry(source_data[:users], user_transforms, team_transforms, idt1_entry)
        idt2_entry_id = Entry.create_without_parsing(idt2_entry).id
        idt2_entry[:id] = idt2_entry_id
        entry_transforms[idt1_entry[:id]] = idt2_entry_id
        migrated_data[:entries].add idt2_entry
      end

      puts "Inserting comments"
      source_data[:comments].each do |idt1_comment|
        idt2_comment = transform_comment(user_transforms, entry_transforms, idt1_comment)
        idt2_comment_id = Reaction.create_without_parsing(idt2_comment).id
        idt2_comment[:id] = idt2_comment_id
        migrated_data[:reactions].add idt2_comment
      end

      puts "Inserting likes"
      source_data[:likes].each do |idt1_like|
        idt2_like = transform_like(user_transforms, entry_transforms, idt1_like)
        idt2_like_id = Reaction.create(idt2_like).id
        idt2_like[:id] = idt2_like_id
        migrated_data[:reactions].add idt2_like
      end

      puts "Inserting tags"
      source_data[:tags].each do |idt1_tag|
        idt2_tag = transform_tag(idt1_tag)
        existing = Tag.find_by(name: idt2_tag[:name].downcase)
        if existing
          idt2_tag_id = existing.id
        else
          idt2_tag_id = Tag.create(idt2_tag).id
        end
        idt2_tag[:id] = idt2_tag_id
        tag_transforms[idt1_tag[:id]] = idt2_tag_id
        migrated_data[:tags].add idt2_tag
      end

      source_data[:tag_dones].each do |idt1_entry_tag|
        idt2_entry_tag = transform_entry_tag(entry_transforms, tag_transforms, idt1_entry_tag)
        idt2_entry_tag_id = EntryTag.create(idt2_entry_tag).id
        idt2_entry_tag[:id] = idt2_entry_tag_id
        migrated_data[:entry_tags].add idt2_entry_tag
      end
    end

    puts "Updating avatars"
    source_data[:users].each do |idt1_user|
      idt2_user_id = user_transforms[idt1_user[:id]]
      u = User.find(idt2_user_id)
      u.remote_portrait_url = idt1_user[:avatar_url]
      u.save(validate: false)
    end

    unless override
      uids = source_data[:users].map{|u| u[:id]}
      # Mark account as migrated
      IDT1_PROD_DB[:accounts_user].where(id: uids).update(migrated: true)
      # Stop sending stuff from idt1
      IDT1_PROD_DB[:main_subscription].where(subscriber_user_id: uids).update(subscribed: false)
    end
  end

  def self.migrate_with_existing_data(source_data, disable_digest_and_reminders=false, override=false, existing_data={})
    # maps from old ids to new ids
    user_transforms = {}
    org_transforms = {}
    team_transforms = {}
    entry_transforms = {}
    tag_transforms = {}

    migrated_data = {
      users:                    Set.new,
      organizations:            Set.new,
      organization_memberships: Set.new,
      teams:                    Set.new,
      team_memberships:         Set.new,
      entries:                  Set.new,
      reactions:                Set.new,
      tags:                     Set.new,
      entry_tags:               Set.new
    }

    ActiveRecord::Base.transaction do
      puts "Inserting users"
      source_data[:users].each do |idt1_user|
        idt2_user = transform_user(idt1_user)
        u = User.new(idt2_user)
        u.save(validate: false)
        idt2_user_id = u.id
        user_transforms[idt1_user[:id]] = idt2_user_id
        idt2_user[:id] = idt2_user_id
        migrated_data[:users].add idt2_user
      end

      puts "Inserting orgs"
      source_data[:organizations].each do |idt1_org|
        idt2_org = transform_organization(idt1_org)

        existing_org = existing_data.fetch(:organizations, []).find {|o| o[:name] == idt2_org[:name] }

        if existing_org.present?
          puts "Looking for existing org #{existing_org[:id]}"
          o = Organization.find(existing_org[:id])
          puts "Org found #{o.inspect}"
        else
          o = Organization.new(idt2_org)
          o.is_migrating = true
          o.save
        end

        update_stripe_subscription_status(o)
        idt2_org_id = o.id
        org_transforms[idt1_org[:id]] = idt2_org_id
        idt2_org[:id] = idt2_org_id
        migrated_data[:organizations].add idt2_org
      end

      puts "Inserting org profiles"
      source_data[:organization_profiles].each do |idt1_profile|
        idt2_profile = transform_org_profile(user_transforms, org_transforms, idt1_profile)
        om = OrganizationMembership.new(idt2_profile)
        om.skip_quantity_update = true
        om.save
        idt2_profile_id = om.id
        idt2_profile[:id] = idt2_profile_id
        migrated_data[:organization_memberships].add idt2_profile
      end

      puts "Inserting teams"
      source_data[:teams].each do |idt1_team|
        new_org = nil
        if idt1_team[:type] == 'TEAM' && idt1_team[:organization_id].nil?  # This team has no org
          new_org = Organization.new(name: idt1_team[:name])
          new_org.is_migrating = true
          team_type = IDT1_DB[:django_content_type].where(model: 'team').first[:id]
          bs = IDT1_DB[:main_billingsubscription].where(billable_content_type_id: team_type, billable_object_id: idt1_team[:id]).first
          if bs
            bc = IDT1_DB[:main_billingcustomer].where(id: bs[:billing_customer_id]).first
            if bc
              new_org.stripe_customer_token = bc[:stripe_customer_id]
              new_org.trial_ends_at = bc[:created] + 14.days
            end
          end
          new_org.save
          update_stripe_subscription_status(new_org)

          source_data[:team_profiles].each do |idt1_profile|
            if idt1_profile[:team_id] == idt1_team[:id]
              om = OrganizationMembership.new(
                user_id: user_transforms[idt1_profile[:user_id]],
                organization_id: new_org.id,
                role: (idt1_profile[:is_admin] ? 'owner' : 'member')
              )
              om.skip_quantity_update = true
              om.save
            end
          end
        end
        idt2_team = transform_team(org_transforms, idt1_team, new_org)

        if team = Team.where(organization_id: idt2_team[:organization_id], name: idt2_team[:name]).first
          idt2_team_id = team.id
        else
          idt2_team_id = Team.create(idt2_team).id
        end

        team_transforms[idt1_team[:id]] = idt2_team_id
        idt2_team[:id] = idt2_team_id
        migrated_data[:teams].add idt2_team
      end

      puts "Inserting team profiles"
      source_data[:team_profiles].each do |idt1_profile|
        source_team = find_source_team(source_data[:teams], idt1_profile[:team_id])
        idt2_profile = transform_team_profile(user_transforms, team_transforms, idt1_profile, disable_digest_and_reminders)
        idt2_profile_id = TeamMembership.create(idt2_profile).id
        idt2_profile[:id] = idt2_profile_id
        if source_team[:type] == 'PERSONAL'
          personal_user = User.find(user_transforms[idt1_profile[:user_id]])
          personal_user.show_personal_team = true
          personal_user.save(validate: false)
        end
        migrated_data[:team_memberships].add idt2_profile
      end

      puts "Inserting entries"
      source_data[:entries].each do |idt1_entry|
        idt2_entry = transform_entry(source_data[:users], user_transforms, team_transforms, idt1_entry)
        idt2_entry_id = Entry.create_without_parsing(idt2_entry).id
        idt2_entry[:id] = idt2_entry_id
        entry_transforms[idt1_entry[:id]] = idt2_entry_id
        migrated_data[:entries].add idt2_entry
      end

      puts "Inserting comments"
      source_data[:comments].each do |idt1_comment|
        idt2_comment = transform_comment(user_transforms, entry_transforms, idt1_comment)
        idt2_comment_id = Reaction.create_without_parsing(idt2_comment).id
        idt2_comment[:id] = idt2_comment_id
        migrated_data[:reactions].add idt2_comment
      end

      puts "Inserting likes"
      source_data[:likes].each do |idt1_like|
        idt2_like = transform_like(user_transforms, entry_transforms, idt1_like)
        idt2_like_id = Reaction.create(idt2_like).id
        idt2_like[:id] = idt2_like_id
        migrated_data[:reactions].add idt2_like
      end

      puts "Inserting tags"
      source_data[:tags].each do |idt1_tag|
        idt2_tag = transform_tag(idt1_tag)
        existing = Tag.find_by(name: idt2_tag[:name].downcase)
        if existing
          idt2_tag_id = existing.id
        else
          idt2_tag_id = Tag.create(idt2_tag).id
        end
        idt2_tag[:id] = idt2_tag_id
        tag_transforms[idt1_tag[:id]] = idt2_tag_id
        migrated_data[:tags].add idt2_tag
      end

      source_data[:tag_dones].each do |idt1_entry_tag|
        idt2_entry_tag = transform_entry_tag(entry_transforms, tag_transforms, idt1_entry_tag)
        idt2_entry_tag_id = EntryTag.create(idt2_entry_tag).id
        idt2_entry_tag[:id] = idt2_entry_tag_id
        migrated_data[:entry_tags].add idt2_entry_tag
      end
    end

    puts "Updating avatars"
    source_data[:users].each do |idt1_user|
      idt2_user_id = user_transforms[idt1_user[:id]]
      u = User.find(idt2_user_id)
      u.remote_portrait_url = idt1_user[:avatar_url]
      u.save(validate: false)
    end

    unless override
      uids = source_data[:users].map{|u| u[:id]}
      # Mark account as migrated
      IDT1_PROD_DB[:accounts_user].where(id: uids).update(migrated: true)
      # Stop sending stuff from idt1
      IDT1_PROD_DB[:main_subscription].where(subscriber_user_id: uids).update(subscribed: false)
    end
  end

  def self.migrate_entries(user, idt2_team_id, source_data, disable_digest_and_reminders=false)
    # maps from old ids to new ids
    user_transforms = {}
    org_transforms = {}
    team_transforms = {}
    entry_transforms = {}
    tag_transforms = {}

    migrated_data = {
      users:                    Set.new,
      organizations:            Set.new,
      organization_memberships: Set.new,
      teams:                    Set.new,
      team_memberships:         Set.new,
      entries:                  Set.new,
      reactions:                Set.new,
      tags:                     Set.new,
      entry_tags:               Set.new
    }

    idt2_user = User.find_by_email_address(user[:email])
    user_transforms[user[:id]] = idt2_user.id

    ActiveRecord::Base.transaction do
      source_data[:teams].each do |idt1_team|
        team_transforms[idt1_team[:id]] = idt2_team_id
      end

      puts "Inserting team profiles"
      source_data[:team_profiles].each do |idt1_profile|
        source_team = find_source_team(source_data[:teams], idt1_profile[:team_id])
        idt2_profile = transform_team_profile(user_transforms, team_transforms, idt1_profile, disable_digest_and_reminders)
        idt2_profile_id = TeamMembership.create(idt2_profile).id
        idt2_profile[:id] = idt2_profile_id
        # if source_team[:type] == 'PERSONAL'
        #   personal_user = User.find(user_transforms[idt1_profile[:user_id]])
        #   personal_user.show_personal_team = true
        #   personal_user.save(validate: false)
        # end
        migrated_data[:team_memberships].add idt2_profile
      end

      puts "Inserting entries"
      source_data[:entries].each do |idt1_entry|
        idt2_entry = transform_entry(source_data[:users], user_transforms, team_transforms, idt1_entry)
        idt2_entry_id = Entry.create_without_parsing(idt2_entry).id
        idt2_entry[:id] = idt2_entry_id
        entry_transforms[idt1_entry[:id]] = idt2_entry_id
        migrated_data[:entries].add idt2_entry
      end

      puts "Inserting comments"
      source_data[:comments].each do |idt1_comment|
        idt2_comment = transform_comment(user_transforms, entry_transforms, idt1_comment)
        idt2_comment_id = Reaction.create_without_parsing(idt2_comment).id
        idt2_comment[:id] = idt2_comment_id
        migrated_data[:reactions].add idt2_comment
      end

      puts "Inserting likes"
      source_data[:likes].each do |idt1_like|
        idt2_like = transform_like(user_transforms, entry_transforms, idt1_like)
        idt2_like_id = Reaction.create(idt2_like).id
        idt2_like[:id] = idt2_like_id
        migrated_data[:reactions].add idt2_like
      end

      puts "Inserting tags"
      source_data[:tags].each do |idt1_tag|
        idt2_tag = transform_tag(idt1_tag)
        existing = Tag.find_by(name: idt2_tag[:name].downcase)
        if existing
          idt2_tag_id = existing.id
        else
          idt2_tag_id = Tag.create(idt2_tag).id
        end
        idt2_tag[:id] = idt2_tag_id
        tag_transforms[idt1_tag[:id]] = idt2_tag_id
        migrated_data[:tags].add idt2_tag
      end

      source_data[:tag_dones].each do |idt1_entry_tag|
        idt2_entry_tag = transform_entry_tag(entry_transforms, tag_transforms, idt1_entry_tag)
        idt2_entry_tag_id = EntryTag.create(idt2_entry_tag).id
        idt2_entry_tag[:id] = idt2_entry_tag_id
        migrated_data[:entry_tags].add idt2_entry_tag
      end
    end
  end

  def self.find_source_team(set, team_id)
    set.each do |team|
      return team if team[:id] == team_id
    end
  end

  def self.data_to_migrate(user_id)
    # Django Content Types
    @org_type     = IDT1_DB[:django_content_type].where(model: 'organization').first[:id]
    @team_type    = IDT1_DB[:django_content_type].where(model: 'team').first[:id]
    @entry_type   = IDT1_DB[:django_content_type].where(model: 'done').first[:id]
    @comment_type = IDT1_DB[:django_content_type].where(model: 'comment').first[:id]

    # Users
    @users = IDT1_DB[:accounts_user]

    # Orgs
    @organizations         = IDT1_DB[:main_organization]
    @organization_profiles = IDT1_DB[:main_organizationprofile]
    @organization_domains  = IDT1_DB[:main_organizationdomain]

    # Teams
    @teams         = IDT1_DB[:main_team]
    @team_profiles = IDT1_DB[:main_teamprofile]

    # Entries
    @entries   = IDT1_DB[:main_entry]
    @comments  = IDT1_DB[:main_comment]
    @likes     = IDT1_DB[:main_like]
    @tags      = IDT1_DB[:main_tag]
    @tag_dones = IDT1_DB[:main_tag_dones]

    # Billing
    @billing_subscriptions = IDT1_DB[:main_billingsubscription]
    @billing_customers     = IDT1_DB[:main_billingcustomer]

    @processed_users = {}

    root_user = @users.where(id: user_id).first

    if root_user.nil?
      puts "No User found with ID #{ARGV[1]}"
      return nil
    end

    source_data = extract_data_for_user(root_user)
    addl_data = []

    begin
      previous_organization_profiles_count = source_data[:organization_profiles].size
      previous_team_profiles_count         = source_data[:team_profiles].size

      uids = source_data[:organization_profiles].map{|op| op[:user_id]}
      @users.where(id: uids, is_active: true).all.map do |u|
        x = extract_data_for_user(u)
        addl_data << x if x
      end

      uids = source_data[:team_profiles].map{|tp| tp[:user_id]}
      @users.where(id: uids, is_active: true).all.map do |u|
        x = extract_data_for_user(u)
        addl_data << x if x
      end

      addl_data.each do |data|
        source_data[:users].merge                 data[:users]
        source_data[:organizations].merge         data[:organizations]
        source_data[:organization_profiles].merge data[:organization_profiles]
        source_data[:organization_domains].merge  data[:organization_domains]
        source_data[:teams].merge                 data[:teams]
        source_data[:team_profiles].merge         data[:team_profiles]
        source_data[:entries].merge               data[:entries]
        source_data[:comments].merge              data[:comments]
        source_data[:likes].merge                 data[:likes]
        source_data[:tags].merge                  data[:tags]
        source_data[:tag_dones].merge             data[:tag_dones]
        source_data[:billing_subscriptions].merge data[:billing_subscriptions]
        source_data[:billing_customers].merge     data[:billing_customers]
      end

    end until previous_organization_profiles_count == source_data[:organization_profiles].size &&
              previous_team_profiles_count == source_data[:team_profiles].size

    source_data
  end

  def self.validate(source_data, override=false)
    return [] if override
    errors = []
    if source_data[:organizations].length > 1
      errors << "We currently don't support upgrading multiple organizations at once. #{source_data[:organizations].map{|o| o[:name]}.join(', ')}"
    end
    #personals = source_data[:teams].select{|t| t[:type] == 'PERSONAL'}.group_by{|t| t[:creator_id]}
    #if personals.any?{|id,teams| teams.length > 1}
    #  errors << "We currently don't support multiple personal teams at once. #{personals.inspect}"
    #end
    #source_data[:teams].each do |team|
    #  if team[:type] == 'TEAM' && team[:organization_id].nil?
    #    errors << "We currently don't support migrating teams that do not belong to an organization. Team #{team[:name]} is not in the organization."
    #  end
    #end

    # create array of emails addresses with original and downcased version to check IDT2
    email_addresses = (source_data[:users].map{|u| u[:email]} + source_data[:users].map{|u| u[:email].downcase}).uniq

    if User.where(email_address: email_addresses).count > 0
      errors << "There are users in the organization that have already been migrated."
    end

    return errors
  end

  def self.extract_data_for_user(user)
    # The internal representation of what data to transfer
    source_data = {
      users:                 Set.new,
      organizations:         Set.new,
      organization_profiles: Set.new,
      organization_domains:  Set.new,
      teams:                 Set.new,
      team_profiles:         Set.new,
      entries:               Set.new,
      comments:              Set.new,
      likes:                 Set.new,
      tags:                  Set.new,
      tag_dones:             Set.new,
      billing_subscriptions: Set.new,
      billing_customers:     Set.new
    }
    return if @processed_users[user[:id]]
    puts "Processing data for user ID #{user[:id]}, Email: #{user[:email]}"
    source_data[:users].add user

    puts "Pulling org profiles"
    org_profiles = @organization_profiles.where(user_id: user[:id], active: true).all
    org_profiles.each do |profile|
      org = @organizations.where(id: profile[:organization_id], active: true).first
      if org
        source_data[:organization_profiles].add profile
        source_data[:organizations].add org
      end
    end
    source_data[:organizations].each do |org|
      source_data[:organization_domains].merge @organization_domains.where(organization_id: org[:id]).all
      source_data[:organization_profiles].merge @organization_profiles.where(organization_id: org[:id], active: true).all
    end

    puts "Pulling team profiles"
    t_profiles = @team_profiles.where(user_id: user[:id], active: true).all
    t_profiles.each do |profile|
      team = @teams.where(id: profile[:team_id], active: true).first
      if team
        source_data[:team_profiles].add profile
        source_data[:teams].add team
      end
    end

    puts "Pulling entries"
    source_data[:teams].each do |team|
      source_data[:team_profiles].merge @team_profiles.where(team_id: team[:id], active: true).all
      source_data[:entries].merge @entries.where(team_id: team[:id], owner_id: user[:id], active: true).all
    end

    entry_ids = source_data[:entries].map{|e| e[:id]}
    puts "Pulling comments"
    source_data[:comments].merge  @comments.where(content_type_id: @entry_type, object_id: entry_ids, active: true).all
    puts "Pulling likes"
    source_data[:likes].merge     @likes.where(content_type_id: @entry_type, object_id: entry_ids).all
    source_data[:tag_dones].merge @tag_dones.where(done_id: entry_ids).all

    comment_ids = source_data[:comments].map{|c| c[:id]}

    puts "Pulling tags"
    tag_done_ids = source_data[:tag_dones].map{|td| td[:tag_id]}
    source_data[:tags].merge @tags.where(id: tag_done_ids).all

    #puts "Pulling billing data"
    #source_data[:organizations].each do |org|
    #  @billing_subscriptions.where(billable_content_type_id: @org_type, billable_object_id: org[:id]).all.each do |bs|
    #    source_data[:billing_subscriptions].add bs
    #    source_data[:billing_customers].merge @billing_customers.where(id: bs[:billing_customer_id]).all
    #  end
    #end
    #source_data[:teams].each do |team|
    #  @billing_subscriptions.where(billable_content_type_id: @team_type, billable_object_id: team[:id]).all.each do |bs|
    #    source_data[:billing_subscriptions].add bs
    #    source_data[:billing_customers].merge @billing_customers.where(id: bs[:billing_customer_id]).all
    #  end
    #end
    @processed_users[user[:id]] = true
    source_data
  end

  def self.transform_user(idt1_user)
    {
      email_address:           idt1_user[:email].downcase,
      crypted_password:        idt1_user[:password],
      full_name:               "#{idt1_user[:first_name]} #{idt1_user[:last_name]}",
      time_zone:               TzMap::TIMEZONES.fetch(idt1_user[:timezone_name], 'Pacific Time (US & Canada)'),
      profile_color:           ('#' + %w(D83F21 EE5E2C F4525B B180C9 FFCD40 6CAE54 9FC97F 3593FF).sample),
      hash_id:                 Digest::SHA1.hexdigest([Time.now, rand, idt1_user[:email]].join)[0,8],
      show_personal_team:      false,
      created_at:              idt1_user[:created],
      updated_at:              Time.now.utc,
      migrated_from_legacy_at: Time.now.utc
    }
  end

  def self.transform_organization(idt1_org)
    org_type = IDT1_DB[:django_content_type].where(model: 'organization').first[:id]
    bs = IDT1_DB[:main_billingsubscription].where(billable_content_type_id: org_type, billable_object_id: idt1_org[:id]).first
    bc = IDT1_DB[:main_billingcustomer].where(id: bs[:billing_customer_id]).first
    {
      name:          idt1_org[:name],
      slug:          idt1_org[:short_name],
      hash_id:       Digest::SHA1.hexdigest([Time.now, rand, idt1_org[:id]].join)[0,8],
      profile_color: ('#' + %w(D83F21 EE5E2C F4525B B180C9 FFCD40 6CAE54 9FC97F 3593FF).sample),
      # If there is no billing customer, they haven't started paying yet or have
      # stopped paying at some point, lets just reset their trial to a new 14 days.
      trial_ends_at: (bc.nil? ? Time.current + 14.days : bc[:created] + 14.days),
      stripe_customer_token: (bc[:stripe_customer_id] if bc),
      created_at:    idt1_org[:created],
      updated_at:    Time.now.utc
    }
  end

  def self.transform_org_profile(user_transforms, org_transforms, idt1_profile)
    {
      user_id: user_transforms[idt1_profile[:user_id]],
      organization_id: org_transforms[idt1_profile[:organization_id]],
      role: (idt1_profile[:is_admin] ? 'owner' : 'member'),
      created_at: idt1_profile[:created],
      updated_at: Time.now.utc
    }
  end

  def self.transform_team(org_transforms, idt1_team, new_org)
    coder = HTMLEntities.new
    if idt1_team[:type] == 'TEAM' && idt1_team[:organization_id].nil?
      org_id = new_org.id
    else
      org_id = org_transforms[idt1_team[:organization_id]]
    end
    {
      name: coder.decode(idt1_team[:name]),
      slug: idt1_team[:short_name],
      hash_id: Digest::SHA1.hexdigest([Time.now, rand, idt1_team[:id]].join)[0,8],
      organization_id: org_id,
      public: true,
      prompt_done: idt1_team[:question],
      created_at: idt1_team[:created],
      updated_at: Time.now.utc
    }
  end

  def self.transform_team_profile(user_transforms, team_transforms, idt1_profile, disable_digest_and_reminders)
    idt2_profile = {
      user_id: user_transforms[idt1_profile[:user_id]],
      team_id: team_transforms[idt1_profile[:team_id]],
      created_at: idt1_profile[:created],
      updated_at: Time.now.utc
    }

    digest_subscription = IDT1_DB[:main_subscription].where(
      active: true,
      source_team_id: idt1_profile[:team_id],
      subscriber_user_id: idt1_profile[:user_id],
      type: 'digest'
    ).first
    reminder_subscription = IDT1_DB[:main_subscription].where(
      active: true,
      source_team_id: idt1_profile[:team_id],
      subscriber_user_id: idt1_profile[:user_id],
      type: 'reminder'
    ).first
    if digest_subscription
      idt2_profile = idt2_profile.merge(bitflag_to_days('digest', digest_subscription[:email_days]))
      idt2_profile[:email_digest_seconds_since_midnight] = bitflag_to_seconds_since_midnight(digest_subscription[:email_hours])
    end
    if reminder_subscription
      idt2_profile = idt2_profile.merge(bitflag_to_days('reminder', reminder_subscription[:email_days]))
      idt2_profile[:email_reminder_seconds_since_midnight] = bitflag_to_seconds_since_midnight(reminder_subscription[:email_hours])
    end


    if disable_digest_and_reminders
      idt2_profile = idt2_profile.merge(bitflag_to_days('digest', 0))
      idt2_profile = idt2_profile.merge(bitflag_to_days('reminder', 0))
    end

    idt2_profile
  end

  def self.transform_entry(users, user_transforms, team_transforms, idt1_entry)
    user = users.select{|u| u[:id] == idt1_entry[:owner_id]}.first
    no_carry_over = user && user[:carry_over_goals] == false
    failed_carry_over = idt1_entry[:goal_carry_over_datetime].nil? ? false : idt1_entry[:goal_carry_over_datetime] < (Time.current - 7.days)
    archived_at = no_carry_over || failed_carry_over ? idt1_entry[:done_date] : nil
    {
      user_id: user_transforms[idt1_entry[:owner_id]],
      team_id: team_transforms[idt1_entry[:team_id]],
      body: idt1_entry[:text],
      occurred_on: idt1_entry[:done_date],
      status: (idt1_entry[:is_goal] && !idt1_entry[:is_goal_completed] ? 'goal' : 'done'),
      hash_id: Digest::SHA1.hexdigest([idt1_entry[:id], Time.now, rand].join),
      created_at: idt1_entry[:created],
      updated_at: Time.now.utc,
      archived_at: archived_at,
      created_by: 'migrator'
    }
  end

  def self.transform_comment(user_transforms, entry_transforms, idt1_comment)
    {
      reactable_type: 'Entry',
      reactable_id: entry_transforms[idt1_comment[:object_id]],
      user_id: user_transforms[idt1_comment[:user_id]],
      body: idt1_comment[:text],
      reaction_type: 'comment',
      created_at: idt1_comment[:created],
      updated_at: Time.now.utc
    }
  end

  def self.transform_like(user_transforms, entry_transforms, idt1_like)
    {
      reactable_type: 'Entry',
      reactable_id: entry_transforms[idt1_like[:object_id]],
      user_id: user_transforms[idt1_like[:user_id]],
      reaction_type: 'like',
      created_at: idt1_like[:created],
      updated_at: Time.now.utc
    }
  end

  def self.transform_tag(idt1_tag)
    {
      name: idt1_tag[:name].downcase,
      created_at: idt1_tag[:created],
      updated_at: Time.now.utc
    }
  end

  def self.transform_entry_tag(entry_transforms, tag_transforms, idt1_entry_tag)
    {
      entry_id: entry_transforms[idt1_entry_tag[:done_id]],
      tag_id: tag_transforms[idt1_entry_tag[:tag_id]],
      created_at: Time.now.utc,
      updated_at: Time.now.utc
    }
  end

  def self.bitflag_to_days(email_type, value)
    list = bitflag_to_list(value)
    days = {
      0 => :monday,
      1 => :tuesday,
      2 => :wednesday,
      3 => :thursday,
      4 => :friday,
      5 => :saturday,
      6 => :sunday
    }
    result = {
      monday: false,
      tuesday: false,
      wednesday: false,
      thursday: false,
      friday: false,
      saturday: false,
      sunday: false
    }
    list.each {|v| result[days[v]] = true}
    Hash[result.map{|k,v| ["#{email_type}_#{k}",v]}]
  end

  def self.bitflag_to_seconds_since_midnight(value)
    list = bitflag_to_list(value)
    if list[0]
      list[0].hours.to_i
    else
      nil
    end
  end

  def self.bitflag_to_list(value)
    result = []
    n = 0
    while value > 0
      if (value % 2) > 0
        result << n
      end
      n += 1
      value /= 2
    end
    result
  end

  def self.update_stripe_subscription_status(organization)
    if subscription = organization.stripe_customer.subscriptions.first
      organization.update_column(:stripe_subscription_status, subscription.status)
    elsif organization.billable_card_on_file?
      organization.update_column(:stripe_subscription_status, 'past_due')
    end
  rescue
    puts "Could not communicate with Stripe --- this should only happen when not using Stripe production keys!"
  end

end
