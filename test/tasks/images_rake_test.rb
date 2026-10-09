require 'test_helper'
require 'rake'

class ImagesRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?('images:destroy_unattached')
    Rake::Task['images:destroy_unattached'].reenable
  end

  test 'destroy_unattached destroys an unattached image uploaded more than a day ago' do
    image = create_image('abandoned', created_at: 2.days.ago)

    stub_cloudflare_images { Rake::Task['images:destroy_unattached'].invoke }

    assert_not Image.exists?(image.id)
  end

  test 'destroy_unattached keeps an unattached image uploaded within the last day' do
    image = create_image('in-progress', created_at: 1.hour.ago)

    stub_cloudflare_images { Rake::Task['images:destroy_unattached'].invoke }

    assert Image.exists?(image.id)
  end

  test 'destroy_unattached keeps an attached image uploaded more than a day ago' do
    image = create_image('map-cover', created_at: 2.days.ago)
    MapRevisionImage.create!(map_revision: map_revisions(:public_one), image: image)

    stub_cloudflare_images { Rake::Task['images:destroy_unattached'].invoke }

    assert Image.exists?(image.id)
  end

  private

  def create_image(name, created_at:)
    users(:me).owned_images.create!(url: "https://imagedelivery.net/mockhash/#{name}/public", created_at: created_at)
  end
end
