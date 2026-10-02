require 'test_helper'

class FulltextIndexTest < ActiveSupport::TestCase
  test 'maps index n-grams that contain stopwords' do
    found = Map.where('MATCH(name, description) AGAINST (? IN BOOLEAN MODE)', '+"map"')

    assert_includes found, maps(:public_one)
  end

  test 'pins index n-grams that are stopwords' do
    found = Pin.where('MATCH(name, comment) AGAINST (? IN BOOLEAN MODE)', '+"is"')

    assert_includes found, pins(:public_one)
  end

  test 'chapters index their title' do
    found = Chapter.where('MATCH(title, content_text) AGAINST (? IN BOOLEAN MODE)', '+"published"')

    assert_includes found, chapters(:my_published)
  end

  test 'chapters keep the text of their content without link targets or images' do
    chapter = chapters(:my_published)

    chapter.revise!(user: users(:me), content: {
                      'root' => {
                        'type' => 'root',
                        'children' => [
                          { 'type' => 'paragraph', 'children' => [
                            { 'type' => 'text', 'text' => '清水寺で抹茶を飲んだ' },
                            { 'type' => 'link', 'url' => 'https://example.com',
                              'children' => [{ 'type' => 'text', 'text' => 'Asian cafe' }] }
                          ] },
                          { 'type' => 'image', 'url' => 'https://example.com/image', 'hero' => 'https://example.com/hero' }
                        ]
                      }
                    })

    assert_equal '["清水寺で抹茶を飲んだ", "Asian cafe"]', chapter.reload.content_text
  end

  test 'users index n-grams that contain stopwords' do
    found = User.where('MATCH(name) AGAINST (? IN BOOLEAN MODE)', '+"wata"')

    assert_includes found, users(:me)
  end
end
