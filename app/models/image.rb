class Image < ApplicationRecord
  belongs_to :user
  has_many :pin_revision_images, dependent: :destroy
  has_many :map_revision_images, dependent: :destroy
  has_many :chapter_revision_images, dependent: :destroy
  has_many :journey_checkin_revision_images, dependent: :destroy

  validates :url,
            presence: true,
            uniqueness: true,
            format: {
              allow_blank: false,
              with: /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/,
              message: I18n.t('messages.api.invalid_uri')
            }
  before_destroy :delete_cloudflare_image

  scope :unattached, lambda {
    referencing_foreign_keys.inject(all) do |relation, foreign_key|
      referencing = foreign_key.from_table.classify.constantize
      relation.where.not(
        foreign_key.primary_key => referencing.where.not(foreign_key.column => nil).select(foreign_key.column)
      )
    end
  }

  def self.referencing_foreign_keys
    connection.tables
              .flat_map { |table| connection.foreign_keys(table) }
              .select { |foreign_key| foreign_key.to_table == table_name }
  end

  def variants
    Cloudflare::Images::NAMED_VARIANTS
      .index_with { |variant| Cloudflare::Images.variant_url(url, variant) }
      .merge(url: url)
  end

  private

  def delete_cloudflare_image
    image_id = Cloudflare::Images.extract_id(url)
    return if image_id.blank?

    Cloudflare::Images.new.delete(image_id)
  rescue Exceptions::InternalServerError, Faraday::Error => e
    Rails.logger.warn("Cloudflare delete failed for image #{id}: #{e.message}")
  end
end
