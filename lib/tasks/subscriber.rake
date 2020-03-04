namespace :subscriber do
  desc 'Run task queue worker'
  task run: :environment do
    pubsub = PubSub.new
    pubsub.run_subscriber!
  end
end
