namespace :staff do
  desc 'Give a role to an email that Cloudflare Access lets into the admin host, such as the first administrator'
  task :grant, %i[email role] => :environment do |_task, args|
    Admin::StaffMember.grant!(email: args.fetch(:email), role: Admin::Role.find_by!(name: args.fetch(:role)))
  end
end

namespace :roles do
  desc 'Create a role'
  task :create, %i[name description] => :environment do |_task, args|
    Admin::Role.create!(name: args.fetch(:name), description: args[:description])
  end

  desc 'Allow a role one permission'
  task :permit, %i[role permission] => :environment do |_task, args|
    Admin::Role.find_by!(name: args.fetch(:role)).permit!(args.fetch(:permission))
  end

  desc 'Take one permission away from a role'
  task :forbid, %i[role permission] => :environment do |_task, args|
    Admin::Role.find_by!(name: args.fetch(:role)).role_permissions.find_by!(permission: args.fetch(:permission)).destroy!
  end
end
