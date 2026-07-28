require 'test_helper'

class UserPreferenceTest < ActiveSupport::TestCase
  test 'a user without snapshots reads as the defaults' do
    assert_empty users(:me).preferences
    assert_equal UserPreference::WEB_PUSH_DEFAULTS,
                 users(:me).web_push_preferences
  end

  test 'saving stores a full snapshot' do
    users(:me).update_web_push_preferences!('liked' => false)

    assert_equal UserPreference::WEB_PUSH_DEFAULTS.merge('liked' => false),
                 users(:me).preferences.last.web_push
  end

  test 'a save without a key keeps the previous choice' do
    users(:me).update_web_push_preferences!('published' => false)
    users(:me).update_web_push_preferences!('liked' => false)

    preferences = users(:me).web_push_preferences

    assert_equal false, preferences['liked']
    assert_equal false, preferences['published']
  end

  test 'the latest snapshot wins' do
    users(:me).update_web_push_preferences!('liked' => false)
    users(:me).update_web_push_preferences!('liked' => true)

    assert_equal true, users(:me).web_push_preferences['liked']
  end

  test 'a stored key outside the known preferences is dropped' do
    users(:me).preferences.create!(web_push: { 'followed' => true })

    assert_not_includes users(:me).web_push_preferences.keys, 'followed'
  end

  test 'a snapshot that does not hold booleans is invalid' do
    ['no', 'false', 1, [true], [], nil].each do |value|
      assert_raises(ActiveRecord::RecordInvalid, "accepted #{value.inspect}") do
        users(:me).preferences.create!(web_push: { 'liked' => value })
      end
    end
  end

  test 'a snapshot that is not an object is invalid' do
    ['garbage', [1, 2], nil].each do |value|
      assert_raises(ActiveRecord::RecordInvalid, "accepted #{value.inspect}") do
        users(:me).preferences.create!(web_push: value)
      end
    end
  end

  test 'a symbol keyed snapshot keeps its choices' do
    users(:me).preferences.create!(web_push: { liked: false })

    assert_equal false, users(:me).web_push_preferences['liked']
  end

  test 'a symbol keyed save overrides the previous choice' do
    users(:me).update_web_push_preferences!(liked: false)

    assert_equal false, users(:me).web_push_preferences['liked']
  end

end
