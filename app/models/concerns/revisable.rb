# frozen_string_literal: true

module Revisable
  extend ActiveSupport::Concern

  included do
    class_attribute :revision_attributes, instance_writer: false, default: []

    enum :status, { published: 'published', deleted: 'deleted' }, validate: true

    attr_accessor :revised_by, :submitted_image_ids

    before_save :reject_change_outside_a_revision, if: :persisted?
    after_save :append_revision, if: :revised_by
    before_destroy :detach_current_revision, prepend: true
  end

  class_methods do
    def publish!(user:, **content)
      new(user: user).revise!(user: user, **content)
    end
  end

  def revise!(user:, image_ids: nil, **content)
    assign_attributes(**content, revised_by: user, submitted_image_ids: image_ids)
    save!

    self
  end

  def delete!(user:)
    revise!(user: user, status: :deleted)
  end

  private

  # A record that has never been revised is a state the backfill exists to
  # resolve, so only a record already pointing at a revision is held to this.
  def reject_change_outside_a_revision
    return if revised_by || current_revision_id.nil?
    return if (changed.map(&:to_sym) & (revision_attributes + [:status])).empty?

    raise ActiveRecord::ReadOnlyRecord, "#{self.class.name} content changes through revise!"
  end

  def append_revision
    revision = revisions.build(
      **slice(*revision_attributes).symbolize_keys,
      user: revised_by,
      status: status,
      images_submitted: !submitted_image_ids.nil?,
      image_ids: submitted_image_ids || current_revision&.image_ids || []
    )

    self.revised_by = nil
    self.submitted_image_ids = nil

    revision.save!
  end

  def detach_current_revision
    update_columns(current_revision_id: nil) if current_revision_id
  end
end
