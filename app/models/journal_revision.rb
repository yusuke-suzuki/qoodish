# frozen_string_literal: true

class JournalRevision < ApplicationRecord
  include Revision

  belongs_to :journal
  belongs_to :user

  alias_method :revisable, :journal

  attr_readonly :journal_id, :user_id, :title, :description

  validates :title,
            presence: true
end
