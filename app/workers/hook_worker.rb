class HookWorker
  include Sidekiq::Worker

  # The default sidekiq retry policy is exponential (to the 4th power) backoff
  # and retrying up to 25 times.
  # Since it's webhooks we're talking about here though, it makes more sense to
  # not retry so often initially and then have a long delay before we stop trying.
  # Mailgun seems to have a pretty reasonable retry policy so we're adopting their scheme of:
  #
  # > Retry during 8 hours at the following intervals before stop trying:
  # > 10 minutes, 10 minutes, 15 minutes, 30 minutes, 1 hour, 2 hours and 4 hours.
  sidekiq_options :retry => 6
  sidekiq_retry_in do |count|
    [10.minutes, 10.minutes, 15.minutes, 30.minutes, 1.hour, 2.hours, 4.hours][count]
  end

  sidekiq_retries_exhausted do |msg|
    # If we exhaust the retries of posting, just log something for now.
    # At some point we might want to consider logging a number of failures and
    # then deleting the webhook after a certain number of failtures.
    Rails.logger.error "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(hook_id, entry_id, event)
    hook = Hook.find(hook_id)
    entry = Entry.eager_load(:team, :user).find(entry_id)
    HookPoster.post_hook(hook, entry, event)
  end
end
