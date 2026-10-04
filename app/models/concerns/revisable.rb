# frozen_string_literal: true

module Revisable
  extend ActiveSupport::Concern

  included do
    class_attribute :revision_attributes, instance_writer: false, default: []
    class_attribute :revision_collections, instance_writer: false, default: []

    attr_accessor :revised_by

    before_create :reject_creation_outside_a_revision
    before_save :reject_change_outside_a_revision, if: :persisted?
    after_save :append_revision, if: :revised_by
  end

  class_methods do
    def record!(user:, **content)
      new(**authored_by(user)).revise!(user: user, **content)
    end

    def authored_by(user) = { user: user }

    def revision_collection_ids
      revision_collections.index_by { |collection| :"#{collection.to_s.singularize}_ids" }
    end
  end

  def revise!(user:, **content)
    @submitted_ids = content.extract!(*self.class.revision_collection_ids.keys)
                            .compact
                            .transform_values { |ids| ids.map(&:to_i).uniq }
    assign_attributes(**content, revised_by: user)
    save!

    self
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
    return if (changed.map(&:to_sym) & revision_attributes).empty?

    raise ActiveRecord::ReadOnlyRecord, "#{self.class.name} content changes through revise!"
  end

  def append_revision
    revision = revisions.build(**revision_content) if revised_anything?

    forget_submission

    revision&.save!
  end

  # A request that submits what the record already says is not an edit, and a
  # log that grows on every such request stops being a record of what changed.
  def revised_anything?
    id_previously_changed? ||
      saved_changes.keys.map(&:to_sym).intersect?(revision_attributes) ||
      submitted_ids.any? { |key, ids| ids.sort != carried_ids(key).sort }
  end

  def revision_content
    {
      **slice(*revision_attributes).symbolize_keys,
      **revision_collection_content,
      user: revised_by
    }
  end

  def revision_collection_content
    self.class.revision_collection_ids.each_with_object({}) do |(key, collection), content|
      content[key] = submitted_ids.fetch(key) { carried_ids(key) }
      content[:"#{collection}_submitted"] = submitted_ids.key?(key)
    end
  end

  def submitted_ids
    @submitted_ids || {}
  end

  def carried_ids(key)
    current_revision&.public_send(key) || []
  end

  def forget_submission
    self.revised_by = nil
    @submitted_ids = nil
  end
end
