class Follow < ActiveRecord::Base
  extend ActsAsFollower::FollowerLib
  extend ActsAsFollower::FollowScopes

  # NOTE: Follows belong to the "followable" and "follower" interface
  belongs_to :followable, polymorphic: true
  belongs_to :follower,   polymorphic: true

  after_create :subscribe_topic, if: :followable_type_map?
  before_destroy :unsubscribe_topic, if: :followable_type_map?

  def block!
    update_attribute(:blocked, true)
  end

  def followable_type_map?
    followable_type == Map.name
  end

  private

  def subscribe_topic
    follower.subscribe_topic("#{followable_type.downcase}_#{followable.id}")
  end

  def unsubscribe_topic
    follower.unsubscribe_topic("#{followable_type.downcase}_#{followable.id}")
  end
end
