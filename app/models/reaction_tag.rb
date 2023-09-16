class ReactionTag < ActiveRecord::Base
	belongs_to :reaction
  belongs_to :tag
end
