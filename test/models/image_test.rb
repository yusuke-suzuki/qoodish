require 'test_helper'

class ImageTest < ActiveSupport::TestCase
  test 'allows attaching an image to a Map owned by the uploader' do
    image = users(:me).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/own-map-image/public'
    )

    assert image.update(imageable: maps(:private))
  end

  test 'rejects attaching an image to a Map owned by another user' do
    image = users(:me).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/foreign-map-image/public'
    )

    refute image.update(imageable: maps(:private_unfollowing))
    assert_includes image.errors[:user], I18n.t('errors.messages.invalid')
  end

  test 'rejects attaching an image to a Review owned by another user' do
    image = users(:me).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/foreign-review-image/public'
    )

    refute image.update(imageable: reviews(:private_you))
    assert_includes image.errors[:user], I18n.t('errors.messages.invalid')
  end

  test 'rejects attaching an image to a different User as imageable' do
    image = users(:me).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/foreign-user-image/public'
    )

    refute image.update(imageable: users(:you))
    assert_includes image.errors[:user], I18n.t('errors.messages.invalid')
  end

  test 'variants returns named variant URLs alongside the base url for a Cloudflare image' do
    image = users(:me).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/qoodish/test/abc/public'
    )

    variants = image.variants
    assert_equal 'https://imagedelivery.net/mockhash/qoodish/test/abc/public', variants[:url]
    assert_equal 'https://imagedelivery.net/mockhash/qoodish/test/abc/avatar', variants[:avatar]
    assert_equal 'https://imagedelivery.net/mockhash/qoodish/test/abc/card', variants[:card]
    assert_equal 'https://imagedelivery.net/mockhash/qoodish/test/abc/hero', variants[:hero]
    assert_equal 'https://imagedelivery.net/mockhash/qoodish/test/abc/ogp', variants[:ogp]
  end

  test 'destroy calls Cloudflare DELETE when url is in imagedelivery.net format' do
    image = users(:me).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/cf-id-abc/public'
    )

    mock = Minitest::Mock.new
    mock.expect(:delete, nil, ['cf-id-abc'])

    Cloudflare::Images.stub :new, mock do
      image.destroy!
    end

    mock.verify
  end

  test 'destroy does not call Cloudflare DELETE when url is not in imagedelivery.net format' do
    image = users(:me).owned_images.create!(
      url: 'https://storage.googleapis.com/qoodish.appspot.com/images/foo.jpg'
    )

    mock = Minitest::Mock.new
    # delete should never be called; mock.verify would fail if it is

    Cloudflare::Images.stub :new, mock do
      image.destroy!
    end

    mock.verify
  end
end
