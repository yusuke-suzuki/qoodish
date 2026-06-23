class Map < ApplicationRecord
  # Shield running instances from the legacy columns the follow-up migration
  # drops, so in-flight INSERTs do not reference a column that is gone.
  self.ignored_columns += %w[shared invitable]

  belongs_to :user
  has_many :reviews, dependent: :destroy
  has_many :notifications, as: :notifiable
  has_many :coauthorships, dependent: :destroy
  has_many :coauthors, through: :coauthorships, source: :user
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarking_users, through: :bookmarks, source: :user
  has_many :coauthorship_invitations, dependent: :destroy
  has_many :votes, as: :votable, dependent: :destroy
  has_many :voters, through: :votes, source: :voter, source_type: User.name
  has_many :images, as: :imageable, dependent: :destroy

  validates :name,
            presence: {
              message: I18n.t('messages.api.map_name_required')
            },
            uniqueness: {
              scope: :user_id,
              message: I18n.t('messages.api.duplicate_map_name'),
              on: :create
            },
            length: {
              allow_blank: false,
              maximum: 30,
              message: I18n.t('messages.api.map_name_exceed')
            }
  validates :description,
            presence: {
              message: I18n.t('messages.api.map_description_required')
            },
            length: {
              allow_blank: false,
              maximum: 200,
              message: I18n.t('messages.api.map_description_exceed')
            }
  validates :user_id,
            presence: {
              message: I18n.t('messages.api.map_author_not_specified')
            }
  validates :images, length: { maximum: 1 }

  before_validation :remove_carriage_return
  after_update :destroy_bookmarks_when_private, if: :saved_change_to_private?

  scope :public_open, lambda {
    where(private: false)
  }

  scope :referenceable_by, lambda { |user|
    where(private: false)
      .or(where(user_id: user.id))
      .or(where(id: Coauthorship.where(user_id: user.id).select(:map_id)))
  }

  scope :editable_by, lambda { |user|
    where(user_id: user.id)
      .or(where(id: Coauthorship.where(user_id: user.id).select(:map_id)))
  }

  scope :bookmarked_by, lambda { |user|
    where(id: Bookmark.where(user_id: user.id).select(:map_id))
  }

  scope :related_to, lambda { |user|
    where(user_id: user.id)
      .or(where(id: Coauthorship.where(user_id: user.id).select(:map_id)))
      .or(where(private: false, id: Bookmark.where(user_id: user.id).select(:map_id)))
  }

  scope :not_bookmarked_by, lambda { |user|
    where.not(id: Bookmark.where(user_id: user.id).select(:map_id))
  }

  scope :active, lambda {
    left_joins(:reviews)
      .group('maps.id')
      .order('max(reviews.created_at) desc')
      .limit(12)
  }

  scope :popular, lambda {
    joins(:bookmarks)
      .group('maps.id')
      .order('count(bookmarks.id) desc')
      .limit(10)
  }

  scope :search_by_words, lambda { |words|
    all.tap do |q|
      words.each { |word| q.where!('name LIKE :word', word: "%#{sanitize_sql_like(word)}%") }
    end
  }

  def image_url
    images.first&.url.to_s
  end

  def image_variants
    primary = images.first
    return nil unless primary

    Cloudflare::Images::NAMED_VARIANTS
      .index_with { |variant| Cloudflare::Images.variant_url(primary.url, variant) }
      .merge(url: primary.url)
  end

  def lat
    latitude.to_f
  end

  def lng
    longitude.to_f
  end

  private

  def remove_carriage_return
    name&.delete!("\r")
    description&.delete!("\r")
  end

  def destroy_bookmarks_when_private
    bookmarks.destroy_all if private?
  end
end
