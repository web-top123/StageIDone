class Hook < ActiveRecord::Base
  belongs_to :user # The creator of the webhook
  belongs_to :team # The team we push data from
end
