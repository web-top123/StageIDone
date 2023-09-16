namespace :users do
  desc "set all legacy plans to standard (small)"
  task validate: :environment do
    csv = CSV.open("tmp/invalid_users.csv","w")

    csv << ['id',
            'email_address',
            'hash_id',
            'errors'
          ]

    User.find_each do |user|
      puts "Processing #{user.email_address}"

      if user.invalid?
        csv << [user.id,
                user.email_address,
                user.hash_id,
                user.errors.full_messages
               ]
      end
    end

    csv.close
  end
end