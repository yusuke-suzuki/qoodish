class User < ApplicationRecord
  has_many :devices, dependent: :destroy
  has_many :maps, dependent: :destroy
  has_many :map_revisions, dependent: :nullify
  has_many :pins, dependent: :destroy
  has_many :notifications, as: :recipient
  has_many :comments, dependent: :destroy
  has_many :coauthorships, dependent: :destroy
  has_many :coauthored_maps, through: :coauthorships, source: :map
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_maps, through: :bookmarks, source: :map
  has_many :sent_coauthorship_invitations,
           class_name: 'CoauthorshipInvitation',
           foreign_key: :inviter_id,
           dependent: :destroy,
           inverse_of: :inviter
  has_many :received_coauthorship_invitations,
           class_name: 'CoauthorshipInvitation',
           foreign_key: :invitee_id,
           dependent: :destroy,
           inverse_of: :invitee
  has_many :votes, as: :voter, dependent: :destroy
  has_many :journeys, dependent: :destroy
  has_many :chapters, dependent: :destroy
  has_one :journal, dependent: :destroy
  has_many :journal_bookmarks, dependent: :destroy
  has_many :bookmarked_journals, through: :journal_bookmarks, source: :journal
  belongs_to :image, optional: true
  has_many :owned_images, class_name: 'Image', dependent: :destroy
  has_many :preferences,
           class_name: 'UserPreference',
           inverse_of: :user,
           dependent: :destroy

  validates :uid,
            presence: true,
            uniqueness: true
  validates :name,
            presence: true
  validates :biography,
            length: {
              allow_blank: true,
              maximum: 160
            }
  validate :image_must_be_owned, if: :image_id_changed?

  before_destroy :detach_image, prepend: true
  before_destroy :delete_id_platform_account
  after_create :create_default_map
  after_create :create_default_journal

  scope :search_by_name, lambda { |name|
    where('name LIKE ?', "%#{name}%")
      .limit(20)
  }

  def web_push_preferences
    UserPreference.effective_web_push(preferences.last&.web_push)
  end

  # Composes the previous effective values with the keys it was sent,
  # so a client built before a preference existed cannot reset it by
  # omission.
  def update_web_push_preferences!(changes)
    preferences.create!(web_push: web_push_preferences.merge(changes))
  end

  def image_url
    image&.url.to_s
  end

  def image_variants
    image&.variants
  end

  def author?(post)
    post.user_id == id
  end

  def map_author?(map)
    map.user_id == id
  end

  def editable?(map)
    map_author?(map) || map.coauthorships.exists?(user_id: id)
  end

  def bookmarkable?(map)
    !map.private && !editable?(map)
  end

  def referenceable_maps
    Map.referenceable_by(self)
  end

  def referenceable_pins
    Pin.referenceable_by(self)
  end

  def editable_maps
    Map.editable_by(self)
  end

  def related_maps
    Map.related_to(self)
  end

  def bookmarking?(map)
    bookmarks.exists?(map: map)
  end

  def bookmark_count
    bookmarks.joins(:map).merge(Map.published).count
  end

  def bookmark!(map)
    bookmarks.create!(map: map)
  end

  def unbookmark!(map)
    bookmarks.find_by!(map: map).destroy!
  end

  def referenceable_vote?(vote)
    return false if vote.votable.blank?

    case vote.votable_type
    when Comment.name
      false
    when Pin.name
      referenceable_pins.exists?(vote.votable.id)
    when Map.name
      referenceable_maps.exists?(vote.votable.id)
    else
      true
    end
  end

  def liked!(votable)
    votes.create_or_find_by!(votable: votable)
  end

  def unliked!(votable)
    votes.find_by!(votable: votable).destroy!
  end

  def liked?(votable)
    votable.voters.any? { |voter| voter.id == id }
  end

  private

  def image_must_be_owned
    return if image_id.blank?
    return if image&.user_id == id

    errors.add(:image, :invalid)
  end

  def detach_image
    update_column(:image_id, nil) if image_id
  end

  def delete_id_platform_account
    id_platform.delete_account(uid)
  end

  def id_platform
    @id_platform ||= IdentityPlatform.new
  end

  def create_default_map
    Map.record!(
      user: self,
      name: "#{name}'s map",
      description: "#{name}'s map."
    )
  end

  def create_default_journal
    create_journal!(title: "#{name}'s journal".truncate(50))
  end
end
