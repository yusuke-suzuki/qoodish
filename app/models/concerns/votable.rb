# frozen_string_literal: true

module Votable
  extend ActiveSupport::Concern

  included do
    has_many :votes, as: :votable, dependent: :destroy
  end

  def liked_by?(user)
    votes.any? { |vote| vote.voter_id == user.id }
  end
end
