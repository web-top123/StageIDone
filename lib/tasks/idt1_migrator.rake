namespace :idt1_migrator do
  desc "run for remaining active users"
  task :run => :environment do
    IDT1_DB = Sequel.connect(ENV['IDT1_DB_URL'])
    USERS   = IDT1_DB[:accounts_user]
    ENTRIES = IDT1_DB[:main_entry]

    def next_user(emails_to_ignore)
      if emails_to_ignore.empty?
        sql = "select *
        from accounts_user
        where migrated = false
        and is_active = true
        and lower(substring(email from position('@' in email)+1 )) not in ('idonethis.com', 'xenon.io')
        and exists (
          select *
          from main_entry
          where main_entry.owner_id = accounts_user.id
          and main_entry.created > '2016-02-29'
          and main_entry.is_goal = false
          limit 1
        )"
      else
        sql = "select *
        from accounts_user
        where migrated = false
        and is_active = true
        and lower(substring(email from position('@' in email)+1 )) not in ('idonethis.com', 'xenon.io')
        and email not in ('#{emails_to_ignore.join('\',\'')}')
        and exists (
          select *
          from main_entry
          where main_entry.owner_id = accounts_user.id
          and main_entry.created > '2016-02-29'
          and main_entry.is_goal = false
          limit 1
        )"
      end

      # USERS.where("migrated = false AND last_login > '2016-02-29' AND is_active = true AND lower(substring(email from position('@' in email)+1 )) not in ('idonethis.com', 'xenon.io')").exclude(email: emails_to_ignore).first
      IDT1_DB.fetch(sql)
    end

    number_to_process = ENV.fetch('NUM', nil).try(:to_i)
    mode = ENV.fetch('MODE', 'production') # pass local for local testing

    emails_to_ignore = []
  
    if mode == 'local'
      emails_to_ignore = User.all.map(&:email_address)
    end

    file = "tmp/migrations#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"
    csv = CSV.open(file,"w")

    csv << ['username', 'id', 'email', 'action', 'time', 'idt2']
    count = 0

    next_user(emails_to_ignore).each do |user|
      if count == number_to_process
        break
      end

      begin
        source_data  = Idt1Migrator.data_to_migrate(user[:id])
        source_errors = Idt1Migrator.validate(source_data)

        if source_errors && source_errors.any?

          if source_data[:organizations].length > 1
            puts "user ID #{user[:id]}, Email: #{user[:email]} could not be migrated as there are multiple organizations"
            csv << [user[:username], user[:id], user[:email], "Migration error: there are multiple organizations", Time.now]
          end

          # create array of emails addresses with original and downcased version to check IDT2
          email_addresses = (source_data[:users].map{|u| u[:email]} + source_data[:users].map{|u| u[:email].downcase}).uniq
          users = User.with_deleted.where(email_address: email_addresses)

          if users.any?
            puts "user ID #{user[:id]}, Email: #{user[:email]} could not be migrated as there are existing users in IDT2"
            csv << [user[:username], user[:id], user[:email], "Migration error: there are existing users in IDT2 #{users.map(&:email_address).join(",")}", Time.now]
          end
        else
          # migrate the user across
          Idt1Migrator.migrate(source_data)
          idt2user = User.find_by_email_address(user[:email].downcase)
          puts "user ID #{user[:id]}, Email: #{user[:email]} Migrated"
          csv << [user[:username], user[:id], user[:email], "Migrated to IDT2", Time.now, "https://beta.idonethis.com/admin/users/#{idt2user.hash_id}"]
        end
      rescue => ex
        puts "user ID #{user[:id]}, Email: #{user[:email]} could not be migrated due to #{ex}"
        csv << [user[:username], user[:id], user[:email], "Migration error #{ex}", Time.now]
      end

      emails_to_ignore += source_data[:users].map{|u| u[:email]}

      count += 1
    end

    puts "MIGRATION DONE!!! Break open the bubbly!! Results logged to #{file}"
  end

  desc "validate for remaining active users"
  task :validate => :environment do
    IDT1_DB = Sequel.connect(ENV['IDT1_DB_URL'])
    USERS   = IDT1_DB[:accounts_user]

    def unmigrated_users
      sql = "select *
      from accounts_user
      where migrated = false
      and is_active = true
      and lower(substring(email from position('@' in email)+1 )) not in ('idonethis.com', 'xenon.io')
      and exists (
        select *
        from main_entry
        where main_entry.owner_id = accounts_user.id
        and main_entry.created > '2016-02-29'
        and main_entry.is_goal = false
        limit 1
      )"

      IDT1_DB.fetch(sql)
    end

    number_to_process = ENV.fetch('NUM', nil).try(:to_i)
    mode = ENV.fetch('MODE', 'production') # pass local for local testing

    emails_to_ignore = []
    
    if mode == 'local'
      emails_to_ignore = User.all.map(&:email_address)
    end

    file = "tmp/migration_validations#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"
    csv = CSV.open(file,"w")

    csv << ['username', 'id', 'email', 'action', 'time', 'idt2']
    count = 0

    unmigrated_users.each do |user|
      puts "Validating user ID #{user[:id]}, Email: #{user[:email]}"

      if count == number_to_process
        break
      end

      begin
        source_data  = Idt1Migrator.data_to_migrate(user[:id])
        source_errors = Idt1Migrator.validate(source_data)

        if source_errors && source_errors.any?

          if source_data[:organizations].length > 1
            puts "user ID #{user[:id]}, Email: #{user[:email]} could not be migrated as there are multiple organizations"
            csv << [user[:username], user[:id], user[:email], "Migration error: there are multiple organizations", Time.now]
          end

          # create array of emails addresses with original and downcased version to check IDT2
          email_addresses = (source_data[:users].map{|u| u[:email]} + source_data[:users].map{|u| u[:email].downcase}).uniq
          users = User.with_deleted.where(email_address: email_addresses)

          if users.any?
            puts "user ID #{user[:id]}, Email: #{user[:email]} could not be migrated as there are existing users in IDT2"
            csv << [user[:username], user[:id], user[:email], "Migration error: there are existing users in IDT2 #{users.map(&:email_address).join(",")}", Time.now]
          end
        else
          puts "user ID #{user[:id]}, Email: #{user[:email]} Ok to migrate"
          csv << [user[:username], user[:id], user[:email], "Ok to migrate to IDT2", Time.now]
        end
      rescue => ex
        puts "user ID #{user[:id]}, Email: #{user[:email]} could not be migrated due to #{ex}"
        csv << [user[:username], user[:id], user[:email], "Migration error #{ex}", Time.now]
      end

      emails_to_ignore += source_data[:users].map{|u| u[:email]}

      count += 1
    end

    puts "VALIDATION COMPLETE Results logged to #{file}"
  end

  desc "migrate for remaining single active users"
  task :single => :environment do
    IDT1_DB      = Sequel.connect(ENV['IDT1_DB_URL'])
    USERS        = IDT1_DB[:accounts_user]
    IDT1_PROD_DB = Sequel.connect(ENV['IDT1_PROD_DB_URL'])

    def unmigrated_users
      sql = "select *
      from accounts_user
      where migrated = false
      and is_active = true
      and lower(substring(email from position('@' in email)+1 )) not in ('idonethis.com', 'xenon.io')
      and exists (
        select *
        from main_entry
        where main_entry.owner_id = accounts_user.id
        and main_entry.created > '2016-02-29'
        and main_entry.is_goal = false
        limit 1
      )"

      IDT1_DB.fetch(sql)
      # USERS.where("migrated = false AND last_login > '2016-02-29' AND is_active = true AND lower(substring(email from position('@' in email)+1 )) not in ('idonethis.com', 'xenon.io')")
    end

    def log(file, row)
      CSV.open(file,"a") do |csv|
        csv << row
      end
    end

    users_with_multiple_orgs = {}
    users_already_in_idt2 = {}

    number_to_process = ENV.fetch('NUM', nil).try(:to_i)
    count = 0

    file = "tmp/single_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"
    deleted_file = "tmp/single_deleted_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"

    log file, ['username', 'id', 'email', 'action', 'time', 'idt2']
    log deleted_file, ['username', 'id', 'email', 'action', 'time', 'idt2']

    unmigrated_users.each do |user|
      if count == number_to_process
        break
      end

      source_data  = Idt1Migrator.data_to_migrate(user[:id])

      # only migrate single users
      next if source_data[:users].length > 1

      # only migrate single organizations
      next if source_data[:organizations].length > 1

      # get IDT2 user
      idt2user = User.with_deleted.where(email_address: user[:email].downcase).first

      # if we find and IDT2 user
      if idt2user.present?
        if idt2user.deleted?
          puts "user ID #{user[:id]}, Email: #{user[:email]} is deleted in IDT2"
          log deleted_file, [user[:username], user[:id], user[:email], "is deleted in IDT2", Time.now, "https://beta.idonethis.com/admin/users/#{idt2user.hash_id}"]
        # and they have no entries in IDT1
        elsif source_data[:entries].length == 0
          # just marked them as migrated
          IDT1_PROD_DB[:accounts_user].where(id: user[:id]).update(migrated: true)
          # # stop sending stuff from idt1
          IDT1_PROD_DB[:main_subscription].where(subscriber_user_id: user[:id]).update(subscribed: false)
          puts "user ID #{user[:id]}, Email: #{user[:email]} Marked as already migrated"
          log file, [user[:username], user[:id], user[:email], "Marked as already migrated", Time.now, "https://beta.idonethis.com/admin/users/#{idt2user.hash_id}"]
        # else if they no entries on IDT2
        elsif idt2user.entries.count == 0
          # delete the IDT2 user and migrate
          idt2user.really_destroy!
          Idt1Migrator.migrate(source_data)
          idt2user = User.find_by_email_address(user[:email].downcase)
          puts "user ID #{user[:id]}, Email: #{user[:email]} Deleted from IDT2 and remigrated"
          log file, [user[:username], user[:id], user[:email], "Deleted from IDT2 and remigrated", Time.now, "https://beta.idonethis.com/admin/users/#{idt2user.hash_id}"]
        end

      else
        # migrate the user across
        Idt1Migrator.migrate(source_data)
        idt2user = User.find_by_email_address(user[:email].downcase)
        puts "user ID #{user[:id]}, Email: #{user[:email]} Migrated"
        log file, [user[:username], user[:id], user[:email], "Migrated to IDT2", Time.now, "https://beta.idonethis.com/admin/users/#{idt2user.hash_id}"]
      end
      count += 1
    end
     puts "MIGRATION COMPLETE.  Results logged to #{file}"
  end

  desc "migrate the user with their personal teams and entries"
  task :user => :environment do
    IDT1_DB      = Sequel.connect(ENV['IDT1_DB_URL'])
    IDT1_PROD_DB = Sequel.connect(ENV['IDT1_PROD_DB_URL'])

    USERS         = IDT1_DB[:accounts_user]
    TEAMS         = IDT1_DB[:main_team]
    TEAM_PROFILES = IDT1_DB[:main_teamprofile]
    ENTRIES       = IDT1_DB[:main_entry]
    COMMENTS      = IDT1_DB[:main_comment]
    LIKES         = IDT1_DB[:main_like]
    TAGS          = IDT1_DB[:main_tag]
    TAG_DONES     = IDT1_DB[:main_tag_dones]

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

    username = ENV.fetch('USERNAME', nil)
    user     = USERS.where(username: username).first

    source_data[:users].add user

    t_profiles = TEAM_PROFILES.where(user_id: user[:id], active: true).all
    t_profiles.each do |profile|
      team = TEAMS.where(id: profile[:team_id], active: true, type: 'PERSONAL').first
      if team
        source_data[:team_profiles].add profile
        source_data[:teams].add team
      end
    end

    source_data[:teams].each do |team|
      source_data[:team_profiles].merge TEAM_PROFILES.where(team_id: team[:id], active: true).all
      source_data[:entries].merge ENTRIES.where(team_id: team[:id], owner_id: user[:id], active: true).all
    end

    entry_ids = source_data[:entries].map{|e| e[:id]}

    entry_type   = IDT1_DB[:django_content_type].where(model: 'done').first[:id]

    source_data[:comments].merge  COMMENTS.where(content_type_id: entry_type, object_id: entry_ids, active: true).all
    source_data[:likes].merge     LIKES.where(content_type_id: entry_type, object_id: entry_ids).all
    source_data[:tag_dones].merge TAG_DONES.where(done_id: entry_ids).all

    comment_ids = source_data[:comments].map{|c| c[:id]}

    tag_done_ids = source_data[:tag_dones].map{|td| td[:tag_id]}
    source_data[:tags].merge TAGS.where(id: tag_done_ids).all

    Idt1Migrator.migrate(source_data)

    puts "#{user[:email]} migrated to IDT2"
  end

  desc 'migrate the user to existing organizations USERNAME=shane ORGANIZATIONS="254|World Scout Bureau,100|Test Me"'
  task :user_existing_organization => :environment do
    IDT1_DB      = Sequel.connect(ENV['IDT1_DB_URL'])
    IDT1_PROD_DB = Sequel.connect(ENV['IDT1_PROD_DB_URL'])

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

    username = ENV.fetch('USERNAME', nil)
    organizations = ENV.fetch('ORGANIZATIONS', "")

    organizations = organizations.split(",")
    organizations = organizations.collect do |r|
      org = r.split("|")
      {id: org.first, name: org.last}
    end

    existing_data = {
      organizations: Set.new
    }

    existing_data[:organizations].merge organizations

    user     = @users.where(username: username).first

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

    if source_data[:users].length > 1
      puts "Found more than 1 user #{source_data[:users].map(&:email)}"
    else
      Idt1Migrator.migrate_with_existing_data(source_data, false, false, existing_data)
    end

    puts "#{user[:email]} migrated to IDT2"
  end

  desc 'migrate the user entries for a team to existing team USERNAME=hana.pasic IDT1_TEAM_ID=127226 IDT2_TEAM_ID=2'
  task :user_team_entries => :environment do
    IDT1_DB      = Sequel.connect(ENV['IDT1_DB_URL'])
    IDT1_PROD_DB = Sequel.connect(ENV['IDT1_PROD_DB_URL'])

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

    source_data = {
      users:                 Set.new,
      teams:                 Set.new,
      team_profiles:         Set.new,
      entries:               Set.new,
      comments:              Set.new,
      likes:                 Set.new,
      tags:                  Set.new,
      tag_dones:             Set.new
    }

    username = ENV.fetch('USERNAME', nil)
    idt1_team_id = ENV.fetch('IDT1_TEAM_ID', nil).to_i
    idt2_team_id = ENV.fetch('IDT2_TEAM_ID', nil).to_i

    user = @users.where(username: username).first
    team = @teams.where(id: idt1_team_id, active: true).first
    profile = @team_profiles.where(user_id: user[:id], team_id: team[:id], active: true).first

    source_data[:users].add user
    source_data[:team_profiles].add profile
    source_data[:teams].add team

    puts "Pulling entries"
    source_data[:entries].merge @entries.where(team_id: team[:id], owner_id: user[:id], active: true).all

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

    Idt1Migrator.migrate_entries(user, idt2_team_id, source_data)

    puts "#{user[:email]} migrated to IDT2"
  end

end
