class SlackEntryIncomingWorker
  include Sidekiq::Worker

  def perform(user_id, team_id, slack_params_body, occurred_on_time)
    Entry.create(
      user_id: user_id,
      team_id: team_id,
      body: slack_params_body,
      status: 'done',
      occurred_on: occurred_on_time,
      created_by: 'slack'
    )
  end
end
