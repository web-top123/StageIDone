module Profilable
  extend ActiveSupport::Concern

  def choose_random_profile_color
    self.profile_color = '#' + %w(f3c600 f59d00 e87e04 d55400 e94b35 c23824 f44488 9c55b8 8f3faf 478cfe 336dcd 2c97de 227fbb 00bd9c 00a085 1ecd6e 1aaf5d).sample
  end
end
