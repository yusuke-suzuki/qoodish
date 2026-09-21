# frozen_string_literal: true

class CommentRevision < ApplicationRecord
  include Revision

  belongs_to :comment
  belongs_to :user

  alias_method :revisable, :comment

  enum :status, { published: 'published', deleted: 'deleted' }, validate: true

  attr_readonly :comment_id, :user_id, :body, :status

  validates :body,
            presence: true
end
