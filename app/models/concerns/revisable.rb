# frozen_string_literal: true

module Revisable
  extend ActiveSupport::Concern

  included do
    class_attribute :revision_attributes, instance_writer: false, default: []

    attr_accessor :revised_by

    before_create :reject_creation_outside_a_revision
    before_save :reject_change_outside_a_revision, if: :persisted?
    after_save :append_revision, if: :revised_by
    before_destroy :detach_current_revision, prepend: true
  end

  class_methods do
    def record!(user:, **content)
      new(**authored_by(user)).revise!(user: user, **content)
    end

    def authored_by(user) = { user: user }
  end

  def revise!(user:, **content)
    assign_attributes(**content, revised_by: user)
    save!

    self
  end

  def discard!(user:)
    revise!(user: user, status: :deleted)
  end

  private

  def reject_creation_outside_a_revision
    return if revised_by

    raise ActiveRecord::ReadOnlyRecord, "#{self.class.name} is recorded through record!"
  end

  # A record that has never been revised is a state the backfill exists to
  # resolve, so only a record already pointing at a revision is held to this.
  def reject_change_outside_a_revision
    return if revised_by || current_revision_id.nil?
    return if (changed.map(&:to_sym) & (revision_attributes + [:status])).empty?

    raise ActiveRecord::ReadOnlyRecord, "#{self.class.name} content changes through revise!"
  end

  def append_revision
    revision = revisions.build(**revision_content)

    forget_submission

    revision.save!
  end

  def revision_content
    {
      **slice(*revision_attributes).symbolize_keys,
      user: revised_by,
      status: status
    }
  end

  def forget_submission
    self.revised_by = nil
  end

  def detach_current_revision
    update_columns(current_revision_id: nil) if current_revision_id
  end
end
