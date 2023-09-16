class HookPoster
  include HTTParty
  format :json
  debug_output $stdout

  def self.post_hook(hook, entry, event)
    res = post(hook.target_url,
         body: [entry.pretty_format].to_json,
         headers: {
           'Content-Type' => 'application/json',
           'X-IDT-Event' => "entry_#{event}"
         })
    if res.code == 410
      hook.destroy
    end
  end
end
