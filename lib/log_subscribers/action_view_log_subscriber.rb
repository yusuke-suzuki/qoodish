# frozen_string_literal: true

module LogSubscribers
  class ActionViewLogSubscriber < ActiveSupport::LogSubscriber
    VIEWS_PATTERN = %r{^app/views/}.freeze

    def render_template(event)
      template = from_rails_root(event.payload[:identifier])
      layout = from_rails_root(event.payload[:layout]) if event.payload[:layout]

      Rails.logger.info({
        message: "Rendered #{template}#{" within #{layout}" if layout}",
        event_type: event.name,
        duration: event.duration,
        gc_time: event.gc_time,
        template: template,
        layout: layout,
        locals: event.payload[:locals]
      }.compact)
    end

    def render_partial(event)
      partial = from_rails_root(event.payload[:identifier])
      layout = from_rails_root(event.payload[:layout]) if event.payload[:layout]

      Rails.logger.info({
        message: "Rendered #{partial}#{" within #{layout}" if layout}",
        event_type: event.name,
        duration: event.duration,
        gc_time: event.gc_time,
        partial: partial,
        layout: layout,
        locals: event.payload[:locals]
      }.compact)
    end

    def render_collection(event)
      template = from_rails_root(event.payload[:identifier])
      layout = from_rails_root(event.payload[:layout]) if event.payload[:layout]

      Rails.logger.info({
        message: "Rendered collection of #{template}#{" within #{layout}" if layout}",
        event_type: event.name,
        duration: event.duration,
        gc_time: event.gc_time,
        template: template,
        layout: layout,
        count: event.payload[:count],
        cache_hits: event.payload[:cache_hits]
      }.compact)
    end

    def render_layout(event)
      layout = from_rails_root(event.payload[:identifier])

      Rails.logger.info({
                          message: "Rendered layout #{layout}",
                          event_type: event.name,
                          duration: event.duration,
                          gc_time: event.gc_time,
                          layout: layout
                        })
    end

    private

    def from_rails_root(string)
      string = string.sub("#{Rails.root}/", '')
      string.sub!(VIEWS_PATTERN, '')
      string
    end
  end
end
