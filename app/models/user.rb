# == Schema Information
#
# Table name: users
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  email          :string(255)
#  uid            :string(255)      not null
#  provider       :string(255)      not null
#  provider_uid   :string(255)      not null
#  provider_token :string(255)
#  image_path     :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_users_on_provider_and_provider_uid  (provider,provider_uid) UNIQUE
#  index_users_on_uid                        (uid)
#

class User < ApplicationRecord
  validates :uid,
            presence: true
  validates :provider_uid,
            presence: true,
            uniqueness: true

  before_validation :get_github_user_id
  before_destroy :delete_profile_image

  PROVIDER_GITHUB = 'github.com'
  PROVIDER_FACEBOOK = 'facebook.com'

  def github_user?
    provider == PROVIDER_GITHUB
  end

  def facebook_user?
    provider == PROVIDER_FACEBOOK
  end

  def upload_profile_image(url)
    url = get_fb_prof_image if facebook_user?
    path = "profile_#{SecureRandom.uuid}.jpg"
    open(url, 'rb') do |data|
      object = bucket.objects[path]
      object.write(data, acl: :public_read, content_type: 'image/jpeg')
    end
    update!(image_path: path)
  end

  def get_fb_prof_image
    return unless facebook_user?
    prof = graph.get_connections('me', '?fields=name,link,picture')
    prof['picture']['data']['url']
  end

  def image_url
    if image_path.present?
      "#{ENV['S3_ENDPOINT']}/#{ENV['S3_BUCKET_NAME']}/#{image_path}"
    else
      ENV['SUBSTITUTE_URL']
    end
  end

  def delete_profile_image
    object = bucket.objects[image_path]
    object.delete
  end

  def get_github_user_id
    return unless github_user? && name.blank?
    user = github_client.fetch_user(provider_token, provider_uid)
    self.name = user['login']
  end

  private

  def client
    @client ||= AWS::S3.new(
      access_key_id: ENV['AWS_ACCESS_KEY'],
      secret_access_key: ENV['AWS_SECRET_KEY']
    )
  end

  def bucket
    @bucket ||= client.buckets[ENV['S3_BUCKET_NAME']]
  end

  def graph
    @graph ||= Koala::Facebook::API.new(provider_token)
  end

  def github_client
    @github_client ||= Github.new(endpoint: ENV['GITHUB_API_ENDPOINT'])
  end
end
