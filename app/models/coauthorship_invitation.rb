class CoauthorshipInvitation < ApplicationRecord
  belongs_to :map
  belongs_to :inviter, class_name: 'User'
  belongs_to :invitee, class_name: 'User'

  enum :status, { pending: 0, accepted: 1, declined: 2 }

  after_create :create_notification

  # Creation-time invariants only: accept!/decline! merely change status and
  # must not re-evaluate whether the invitation could be created (a migrated
  # user may already be a coauthor while holding a pending invitation).
  validates :invitee_id,
            uniqueness: {
              scope: :map_id,
              conditions: -> { where(status: :pending) },
              message: I18n.t('messages.api.duplicate_pending_invitation')
            },
            on: :create
  validate :invitee_is_not_author, on: :create
  validate :invitee_is_not_coauthor, on: :create

  def accept!
    transaction do
      accepted!
      Coauthorship.find_or_create_by!(map: map, user: invitee)
    end
  end

  def decline!
    declined!
  end

  private

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
