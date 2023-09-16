class MigrationWorker
  include Sidekiq::Worker

  def perform(username, disable_digest_and_reminders, override_validation)
    (@user, @org, @owned_teams) = Idt1Migrator.org_and_teams(username)
    @source_data = Rails.cache.fetch("migration_id_#{@user[:id]}", expires_in: 10.minutes) do
      Idt1Migrator.data_to_migrate(@user[:id])
    end
    Idt1Migrator.migrate(@source_data, disable_digest_and_reminders, override_validation)
    MigrationMailer.migration_complete(@user[:email], true).deliver_now
  rescue StandardError => e
    Raven.capture_exception(e)
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    MigrationMailer.migration_complete(@user[:email], false).deliver_now
  end
end
