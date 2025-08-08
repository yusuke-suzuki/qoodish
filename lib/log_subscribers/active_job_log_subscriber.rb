# frozen_string_literal: true

module LogSubscribers
  class ActiveJobLogSubscriber < ActiveSupport::LogSubscriber
    def enqueue(event)
      job = event.payload[:job]
      ex = event.payload[:exception_object] || job.enqueue_error

      job_info = format_job(job)
      adapter = adapter_name(event)

      if ex
        Rails.logger.error({
                             message: "Failed enqueuing #{job.class.name}: #{ex.class} (#{ex.message})",
                             adapter: adapter,
                             job: job_info,
                             error: ex
                           })
      elsif event.payload[:aborted]
        Rails.logger.info({
                            message: "Failed enqueuing #{job.class.name}, a before_enqueue callback halted the enqueuing execution.",
                            adapter: adapter,
                            job: job_info
                          })
      else
        message = "Enqueued #{job.class.name}#{job_info[:scheduled_at] ? " at #{job_info[:scheduled_at]}" : ''}"
        Rails.logger.info({
                            message: message,
                            adapter: adapter,
                            job: job_info
                          })
      end
    end

    def enqueue_at(event)
      enqueue(event)
    end

    def enqueue_all(event)
      jobs = event.payload[:jobs]
      adapter = adapter_name(event)
      enqueued_jobs = jobs.select(&:successfully_enqueued?)
      failed_count = jobs.size - enqueued_jobs.size

      log_data = {
        adapter: adapter,
        enqueued_count: enqueued_jobs.size,
        failed_count: failed_count,
        jobs: enqueued_jobs.map { |job| format_job(job) }
      }

      if failed_count.zero?
        message = enqueued_jobs_message(adapter, enqueued_jobs)
        Rails.logger.info(log_data.merge(message: message))
      elsif enqueued_jobs.any?
        success_message = enqueued_jobs_message(adapter, enqueued_jobs)
        failure_message = "Failed enqueuing #{failed_count} #{'job'.pluralize(failed_count)}"
        Rails.logger.warn(log_data.merge(message: "#{success_message}. #{failure_message}"))
      else
        message = "Failed enqueuing #{failed_count} #{'job'.pluralize(failed_count)} to #{adapter}"
        Rails.logger.error(log_data.merge(message: message))
      end
    end

    def perform_start(event)
      job = event.payload[:job]
      job_info = format_job(job)

      message = "Performing #{job.class.name}" + (job_info[:enqueued_at] ? " enqueued at #{job_info[:enqueued_at]}" : '')

      Rails.logger.info({
                          message: message,
                          adapter: adapter_name(event),
                          job: job_info
                        })
    end

    def perform(event)
      job = event.payload[:job]
      ex = event.payload[:exception_object]

      log_data = {
        adapter: adapter_name(event),
        job: format_job(job),
        duration: event.duration
      }

      if ex
        message = "Error performing #{job.class.name}: #{ex.class} (#{ex.message})"
        Rails.logger.error(log_data.merge(message: message, error: ex))
      elsif event.payload[:aborted]
        message = "Error performing #{job.class.name}: a before_perform callback halted the job execution"
        Rails.logger.error(log_data.merge(message: message))
      else
        message = "Performed #{job.class.name}"
        Rails.logger.info(log_data.merge(message: message))
      end
    end

    def enqueue_retry(event)
      job = event.payload[:job]
      ex = event.payload[:error]
      wait = event.payload[:wait]

      message = "Retrying #{job.class} after #{job.executions} attempts in #{wait.to_i} seconds"
      message += ex ? ", due to a #{ex.class} (#{ex.message})." : '.'

      Rails.logger.info({
        message: message,
        adapter: adapter_name(event),
        job: format_job(job),
        wait_seconds: wait.to_i,
        error: ex
      }.compact)
    end

    def retry_stopped(event)
      job = event.payload[:job]
      ex = event.payload[:error]
      message = "Stopped retrying #{job.class} due to a #{ex.class} (#{ex.message}), which reoccurred on #{job.executions} attempts."
      Rails.logger.error({
                           message: message,
                           adapter: adapter_name(event),
                           job: format_job(job),
                           error: ex
                         })
    end

    def discard(event)
      job = event.payload[:job]
      ex = event.payload[:error]
      message = "Discarded #{job.class} due to a #{ex.class} (#{ex.message})."
      Rails.logger.error({
                           message: message,
                           adapter: adapter_name(event),
                           job: format_job(job),
                           error: ex
                         })
    end

    def interrupt(event)
      job = event.payload[:job]
      description = event.payload[:description]
      reason = event.payload[:reason]
      message = "Interrupted #{job.class} #{description} (#{reason})"
      Rails.logger.info({
                          message: message,
                          adapter: adapter_name(event),
                          job: format_job(job),
                          description: description,
                          reason: reason
                        })
    end

    def resume(event)
      job = event.payload[:job]
      description = event.payload[:description]
      message = "Resuming #{job.class} #{description}"
      Rails.logger.info({
                          message: message,
                          adapter: adapter_name(event),
                          job: format_job(job),
                          description: description
                        })
    end

    def step(event)
      job = event.payload[:job]
      step = event.payload[:step]
      ex = event.payload[:exception_object]

      log_data = {
        adapter: adapter_name(event),
        job: format_job(job),
        step_name: step.name,
        cursor: step.cursor,
        duration: event.duration
      }

      if event.payload[:interrupted]
        message = "Step '#{step.name}' interrupted at cursor '#{step.cursor}' for #{job.class}"
        Rails.logger.info(log_data.merge(message: message))
      elsif ex
        message = "Error during step '#{step.name}' at cursor '#{step.cursor}' for #{job.class}: #{ex.class} (#{ex.message})"
        Rails.logger.error(log_data.merge(message: message, error: ex))
      else
        message = "Step '#{step.name}' completed for #{job.class}"
        Rails.logger.info(log_data.merge(message: message))
      end
    end

    private

    def format_job(job)
      job_data = {
        class: job.class.name,
        id: job.job_id,
        provider_job_id: job.provider_job_id,
        queue_name: job.queue_name,
        priority: job.priority,
        executions: job.executions,
        exception_executions: job.exception_executions,
        locale: job.locale,
        timezone: job.timezone,
        enqueued_at: job.enqueued_at&.utc&.iso8601(9),
        scheduled_at: job.scheduled_at ? Time.at(job.scheduled_at).utc.iso8601(9) : nil
      }

      job_data[:arguments] = job.arguments.map { |arg| format(arg) } if job.class.log_arguments? && job.arguments.any?

      job_data.compact
    end

    def adapter_name(event)
      ActiveJob.adapter_name(event.payload[:adapter])
    end

    def format(arg)
      case arg
      when Hash
        arg.transform_values { |value| format(value) }
      when Array
        arg.map { |value| format(value) }
      when GlobalID::Identification
        begin
          arg.to_global_id
        rescue StandardError
          arg
        end
      else
        arg
      end
    end

    def enqueued_jobs_message(adapter_name, enqueued_jobs)
      enqueued_count = enqueued_jobs.size
      job_classes_counts = enqueued_jobs.map(&:class).tally.sort_by { |_k, v| -v }
      "Enqueued #{enqueued_count} #{'job'.pluralize(enqueued_count)} to #{adapter_name}"\
        " (#{job_classes_counts.map { |klass, count| "#{count} #{klass}" }.join(', ')})"
    end
  end
end
