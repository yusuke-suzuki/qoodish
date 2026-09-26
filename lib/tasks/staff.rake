namespace :staff do
  desc 'List staff members with their roles'
  task list: :environment do
    Admin::StaffMember.preload(:roles).order(:email).each do |member|
      puts [
        member.email,
        member.roles.map(&:name).sort.join(',').presence || '(no roles)',
        member.revoked_at ? "revoked #{member.revoked_at.utc.iso8601}" : 'active'
      ].join("\t")
    end
  end

  desc 'Give a role to an email that Cloudflare Access lets into the admin host'
  task :grant, %i[email role] => :environment do |_task, args|
    member = Admin::StaffMember.find_or_create_by!(email: args.fetch(:email))
    member.grant!(Admin::Role.find_by!(name: args.fetch(:role)))
  end

  desc 'Take one role away from a staff member'
  task :unassign, %i[email role] => :environment do |_task, args|
    member = Admin::StaffMember.find_by!(email: args.fetch(:email))
    member.staff_member_roles.find_by!(role: Admin::Role.find_by!(name: args.fetch(:role))).destroy!
  end

  desc 'Revoke a staff member, keeping the record their decisions refer to'
  task :revoke, [:email] => :environment do |_task, args|
    Admin::StaffMember.find_by!(email: args.fetch(:email)).revoke!
  end
end

namespace :roles do
  desc 'List roles with their permissions and members'
  task list: :environment do
    Admin::Role.preload(:role_permissions, :staff_members).order(:name).each do |role|
      puts [
        role.name,
        role.role_permissions.map(&:permission).sort.join(',').presence || '(no permissions)',
        role.staff_members.map(&:email).sort.join(',').presence || '(no members)'
      ].join("\t")
    end
  end

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
