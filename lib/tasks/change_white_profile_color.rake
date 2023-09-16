namespace :change_white_profile_color do
  desc "Change white profile color of users and organizations to random color"
  task change: :environment do
    User.where(profile_color: '#ff599').find_each(batch_size: 100) do |user|
      user.choose_random_profile_color
      user.save
    end
    Organization.where(profile_color: '#ff599').find_each(batch_size: 100) do |org|
      org.choose_random_profile_color
      org.save
    end
  end
end
