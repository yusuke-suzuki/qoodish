MAX_CONTENT_SNAPSHOT_LENGTH = 1000

class ContentSnapshot
  def initialize(moderatable)
    @moderatable = moderatable
  end

  def text
    body&.truncate(MAX_CONTENT_SNAPSHOT_LENGTH)
  end

  private

  def body
    case @moderatable
    when Review
      [@moderatable.name, @moderatable.comment].join("\n")
    when Comment
      @moderatable.body
    when Map
      [@moderatable.name, @moderatable.description].join("\n")
    when Chapter
      [@moderatable.title, chapter_text(@moderatable.content)].join("\n")
    when Journal
      [@moderatable.title, @moderatable.description].join("\n")
    when User
      [@moderatable.name, @moderatable.biography].join("\n")
    end
  end

  def chapter_text(node)
    case node
    when Hash
      node['text'].is_a?(String) ? node['text'] : chapter_text(node['children'] || node['root'])
    when Array
      node.map { |child| chapter_text(child) }.compact.join(' ')
    end
  end
end
