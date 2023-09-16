require 'test_helper'

class Integrations::InboundEmailsControllerTest < ActionController::TestCase
  before do
    FakeWeb.register_uri(:post, 'http://fakeweb.com', body: 'ok')
    Timecop.freeze(Time.utc(2016,4,1,16,45,8))
    @token = 'abc'
    @timestamp = Time.current.to_i
    data = [@timestamp, @token].join
    digest = OpenSSL::Digest::SHA256.new
    @signature = OpenSSL::HMAC.hexdigest(digest, Rails.application.config.mailgun[:inbound_email_api_key], data)
  end

  after do
    Timecop.return
  end

  test 'removes signature from email but not sender sign-off, nor entries with --' do
    assert_difference 'Entry.count', 6 do
      post :create, {
        token: @token,
        timestamp: @timestamp,
        signature: @signature,
        sender: users(:user_one).email_address,
        recipient: "#{teams(:team_one).slug}@entry.idonethis.com",
        'stripped-html' => <<-HTML
                              <span class='entry'>this is an entry</span>
                              <div>and this is another</div>
                              <p>[] and this is a--goal</p>
                              [ ] and a second goal<br/>

                              Cheers,<br/>
                              Teri<br/>
                              <p>------
                              Disclaimer:
                              Blah blah
                              </p>
                           HTML
      }
      assert_response :success
    end
    assert_equal "Teri", Entry.last.body
  end


  test 'posting from existing user into existing team' do
    assert_difference 'Entry.count', 4 do
      post :create, {
        token: @token,
        timestamp: @timestamp,
        signature: @signature,
        sender: users(:user_one).email_address,
        recipient: "#{teams(:team_one).slug}@entry.idonethis.com",
        'stripped-html' => <<-HTML
                              <span class='entry'>this is an entry</span>
                              <div>and this is another</div>
                              <p>[] and this is a goal</p>
                              [ ] and a second goal
                           HTML
      }
      assert_response :success
    end
    assert_equal 2, Entry.where(status: 'goal').count
  end

  test 'posting br-only html from existing user into existing team' do
    assert_difference 'Entry.count', 4 do
      post :create, {
        token: @token,
        timestamp: @timestamp,
        signature: @signature,
        sender: users(:user_one).email_address,
        recipient: "#{teams(:team_one).slug}@entry.idonethis.com",
        'stripped-html' => <<-HTML
                              this is an entry<br/>
                              and this is another<br/>
                              [] and this is a goal<br/>
                              [ ] and a second goal<br/>
                           HTML
      }
      assert_response :success
    end
    assert_equal 2, Entry.where(status: 'goal').count
  end

  test 'posting from existing user into non-existing team' do
    assert_difference 'Entry.count', 0 do
      post :create, {
        token: @token,
        timestamp: @timestamp,
        signature: @signature,
        sender: users(:user_one).email_address,
        recipient: 'randomname@entry.idonethis.com',
        'stripped-text' => <<-HTML
                              <span class='entry'>this is an entry</span>
                              <div>and this is another</div>
                              <p>[] and this is a goal</p>
                              [ ] and a second goal
                           HTML
      }
      assert_response 406
    end
  end

  test 'posting from non-existing user into existing team' do
    assert_difference 'Entry.count', 0 do
      post :create, {
        token: @token,
        timestamp: @timestamp,
        signature: @signature,
        sender: 'iforgot@myemail.com',
        recipient: "#{teams(:team_one).slug}@entry.idonethis.com",
        'stripped-text' => <<-HTML
                              <span class='entry'>this is an entry</span>
                              <div>and this is another</div>
                              <p>[] and this is a goal</p>
                              [ ] and a second goal
                           HTML
      }
      assert_response 406
    end
  end

  test 'posting with date in subject creates entry for that date' do
    assert_difference 'Entry.count', 1 do
      post :create, {
        subject: "RE: What'd you get done today? - myteam - April 30",
        token: @token,
        timestamp: @timestamp,
        signature: @signature,
        sender: users(:user_one).email_address,
        recipient: "#{teams(:team_one).slug}@entry.idonethis.com",
        'stripped-html' => "<span class='entry'>this is an entry</span>"
      }
      assert_response :success
    end
    assert_equal 1, users(:user_one).entries.where(occurred_on: '2016-04-30').count
  end

  test 'posting with date with year in subject creates entry for that date' do
    assert_difference 'Entry.count', 1 do
      post :create, {
        subject: "RE: What'd you get done today? - myteam - April 30, 2015",
        token: @token,
        timestamp: @timestamp,
        signature: @signature,
        sender: users(:user_one).email_address,
        recipient: "#{teams(:team_one).slug}@entry.idonethis.com",
        'stripped-html' => "<span class='entry'>this is an entry</span>"
      }
      assert_response :success
    end
    assert_equal 1, users(:user_one).entries.where(occurred_on: '2015-04-30').count
  end

  test 'posting with 30th December in subject on January 1st 2017 should create entry for 2016' do
    Timecop.freeze(Time.utc(2017,1,1,16,45,8))

    assert_difference 'Entry.count', 1 do
      post :create, {
        subject: "RE: What'd you get done today? - myteam - December 30",
        token: @token,
        timestamp: @timestamp,
        signature: @signature,
        sender: users(:user_one).email_address,
        recipient: "#{teams(:team_one).slug}@entry.idonethis.com",
        'stripped-html' => "<span class='entry'>this is an entry</span>"
      }
      assert_response :success
    end
    assert_equal 1, users(:user_one).entries.where(occurred_on: '2016-12-30').count
  end
end
