namespace :subscriber do
  desc 'Run task queue worker'
  task run: :environment do
    PubSub.run_subscriber!
  end
end
