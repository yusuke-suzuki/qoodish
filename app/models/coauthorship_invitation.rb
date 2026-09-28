class CoauthorshipInvitation < ApplicationRecord
  belongs_to :map
  belongs_to :inviter, class_name: 'User'
  belongs_to :invitee, class_name: 'User'

  enum :status, { pending: 0, accepted: 1, declined: 2 }

  after_create :create_notification
  after_update :join_map_as_coauthor, if: -> { saved_change_to_status?(to: 'accepted') }

  validates :invitee_id,
            uniqueness: {
              scope: :map_id,
              conditions: -> { where(status: :pending) },
              message: I18n.t('messages.api.duplicate_pending_invitation')
            },
            on: :create
  validate :invitee_is_not_author, on: :create
  validate :invitee_is_not_coauthor, on: :create
  validates :invitee_id,
            exclusion: {
              in: lambda { |invitation|
                [invitation.inviter, invitation.map&.user].compact.flat_map(&:blocked_with_user_ids)
              },
              message: :blocked_interaction
            },
            on: :create

  scope :between, lambda { |user, other|
    where(inviter_id: user.id, invitee_id: other.id)
      .or(where(inviter_id: other.id, invitee_id: user.id))
      .or(where(map_id: user.maps.select(:id), invitee_id: other.id))
      .or(where(map_id: other.maps.select(:id), invitee_id: user.id))
  }

  private

  def join_map_as_coauthor
    Coauthorship.find_or_create_by!(map: map, user: invitee)
  end

  def invitee_is_not_author
    return if map.blank? || invitee_id.blank?

    errors.add(:invitee_id, I18n.t('messages.api.invitation_invitee_already_author')) if map.user_id == invitee_id
  end

  def invitee_is_not_coauthor
    return if map.blank? || invitee_id.blank?

    errors.add(:invitee_id, I18n.t('messages.api.duplicate_coauthor')) if map.coauthorships.exists?(user_id: invitee_id)
  end

  def create_notification
    Notification.create!(
      notifiable: map,
      notifier: inviter,
      recipient: invitee,
      key: 'coauthor_invited'
    )
  end
end
