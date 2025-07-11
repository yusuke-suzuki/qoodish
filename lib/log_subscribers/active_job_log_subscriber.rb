module LogSubscribers
  class ActiveJobLogSubscriber < ActiveSupport::LogSubscriber
    def enqueue_at(event)
      job = event.payload[:job]

      Rails.logger.info({
                          message: "Enqueued #{job.class.name} (Job ID: #{job.job_id})",
                          event_type: event.name,
                          adapter: event.payload[:adapter].class.name,
                          job: format_job(job)
                        })
    end

    def enqueue(event)
      job = event.payload[:job]

      Rails.logger.info({
                          message: "Enqueued #{job.class.name} (Job ID: #{job.job_id})",
                          event_type: event.name,
                          adapter: event.payload[:adapter].class.name,
                          job: format_job(job)
                        })
    end

    def enqueue_retry(event)
      job = event.payload[:job]

      Rails.logger.info({
                          message: "Retrying #{job.class.name} (Job ID: #{job.job_id}) in #{event.payload[:wait].to_i} seconds due to #{event.payload[:error].class}",
                          event_type: event.name,
                          adapter: event.payload[:adapter].class.name,
                          wait: event.payload[:wait],
                          error: event.payload[:error],
                          job: format_job(job)
                        })
    end

    def enqueue_all(event)
      Rails.logger.info({
                          message: "Enqueued #{event.payload[:jobs].count} jobs",
                          event_type: event.name,
                          adapter: event.payload[:adapter].class.name,
                          job_count: event.payload[:jobs].count,
                          jobs: event.payload[:jobs].map { |job| format_job(job) }
                        })
    end

    def perform_start(event)
      Rails.logger.info({
                          message: "Performing #{event.payload[:job].class.name} (Job ID: #{event.payload[:job].job_id})",
                          event_type: event.name,
                          adapter: event.payload[:adapter].class.name,
                          job: format_job(event.payload[:job])
                        })
    end

    def perform(event)
      job = event.payload[:job]
      duration = event.duration

      Rails.logger.info({
                          message: "Performed #{job.class.name} (Job ID: #{job.job_id}) #{format_duration(duration)}",
                          event_type: event.name,
                          duration: duration,
                          adapter: event.payload[:adapter].class.name,
                          job: format_job(job),
                          db_runtime: event.payload[:db_runtime]
                        })
    end

    def retry_stopped(event)
      job = event.payload[:job]

      Rails.logger.warn({
                          message: "Retry stopped for #{job.class.name} (Job ID: #{job.job_id}) due to #{event.payload[:error].class}",
                          event_type: event.name,
                          adapter: event.payload[:adapter].class.name,
                          job: format_job(job),
                          error: event.payload[:error]
                        })
    end

    def discard(event)
      job = event.payload[:job]

      Rails.logger.warn({
                          message: "Discarded #{job.class.name} (Job ID: #{job.job_id}) due to #{event.payload[:error].class}",
                          event_type: event.name,
                          adapter: event.payload[:adapter].class.name,
                          job: format_job(job),
                          error: event.payload[:error]
                        })
    end

    private

    def format_duration(duration)
      "(Duration: #{duration.round(1)}ms)"
    end

    def format_job(job)
      {
        class: job.class.name,
        job_id: job.job_id,
        arguments: job.arguments,
        enqueue_error: job.enqueue_error,
        enqueued_at: job.enqueued_at,
        exception_executions: job.exception_executions,
        executions: job.executions,
        locale: job.locale,
        priority: job.priority,
        provider_job_id: job.provider_job_id,
        queue_name: job.queue_name,
        scheduled_at: job.scheduled_at,
        timezone: job.timezone
      }
    end
  end
end
