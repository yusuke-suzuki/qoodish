# frozen_string_literal: true

class UserRevision < ApplicationRecord
  include Revision

  belongs_to :user

  alias_method :revisable, :user

  attr_readonly :user_id, :name, :biography
end
