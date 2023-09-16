require 'test_helper'
require 'mailgun_emailed_entries_presenter'

class MailgunEmailedEntriesPresenterTest < ActiveSupport::TestCase
  let(:sender) {
    {
      name: 'Teri',
      phone: '+1-415-1234',
    }
  }
  let(:sender_sign_off) {
    "\n\n#{sender[:name]}\n#{sender[:phone]}"
  }
  let(:signature_pattern_1) {
    "\n\n--------------------------------------\nPrivacy and Confidential Notice:\nBlah blah ...\nBlah blah ..."
  }

  # NOTE: stripped-text from Mailgun supposedly have signature parsed out already
  let(:mailgun_stripped_text_emailed_entries) {
    {
      'stripped-text' => "Entry #1\n" +
                         "Imperfect Entry #1",
    }
  }
  let(:mailgun_stripped_text_prefixed_emailed_entries) {
    {
      'stripped-text' => "* Prefixed Entry #1\n" +
                         "*Imperfect Prefixed Entry #1",
    }
  }
  let(:mailgun_stripped_text_prefixed_emailed_split_entries) {
    {
      'stripped-text' => "* Prefixed Entry #1\n" +
                         "*Prefixed Entry #1\nAnd Split",
    }
  }
  let(:mailgun_stripped_text_prefixed_emailed_entries_with_sender_sign_off_and_signature) {
    {
      'stripped-text' => "* Prefixed Entry #1\n" +
                         "*Imperfect Prefixed Entry #1\n" +
                         sender_sign_off +
                         signature_pattern_1,
    }
  }

  # NOTE: THere are some \n in front of html_cdata
  let(:html_cdata) {
    "\n<style><!--\n/* Font Definitions */\n@font-face\n\t{font-family:\"Cambria Math\";\n\tpanose-1:2 4 5 3 5 4 6 3 2 4;}\n@font-face\n\t{font-family:Calibri;\n\tpanose-1:2 15 5 2 2 2 4 3 2 4;}\n/* Style Definitions */\np.MsoNormal, li.MsoNormal, div.MsoNormal\n\t{margin:0in;\n\tmargin-bottom:.0001pt;\n\tfont-size:12.0pt;\n\tfont-family:\"Times New Roman\",serif;}\nh1\n\t{ mso-style-priority:9;\n\tmso-style-link:\"Heading 1 Char\";\n\tmso-margin-top-alt:auto;\n\tmargin-right:0in;\n\tmso-margin-bottom -alt:auto;\n\tmargin-left:0in;\n\tfont-size:24.0pt;\n\tfont-family:\"Times New Roman\",serif;\n\tfont-weight:bold;}\na:link, span .MsoHyperlink\n\t{mso-style-priority:99;\n\tcolor:blue;\n\ttext-decoration:underline;}\na:visited, span.MsoHyperlinkFollowed\n\t{ mso-style-priority:99;\n\tcolor:purple;\n\ttext-decoration:underline;}\np\n\t{mso-style-priority:99;\n\tmso-margin-top-alt:auto;\ n\tmargin-right:0in;\n\tmso-margin-bottom-alt:auto;\n\tmargin-left:0in;\n\tfont-size:12.0pt;\n\tfont-family:\"Times New Roman\",s erif;}\np.msonormal0, li.msonormal0, div.msonormal0\n\t{mso-style-name:msonormal;\n\tmso-margin-top-alt:auto;\n\tmargin-right:0in ;\n\tmso-margin-bottom-alt:auto;\n\tmargin-left:0in;\n\tfont-size:12.0pt;\n\tfont-family:\"Times New Roman\",serif;}\nspan.Headin g1Char\n\t{mso-style-name:\"Heading 1 Char\";\n\tmso-style-priority:9;\n\tmso-style-link:\"Heading 1\";\n\tfont-family:\"Calibri Light\",sans-serif;\n\tcolor:#2E74B5;}\np.salutation, li.salutation, div.salutation\n\t{mso-style-name:salutation;\n\tmso-margin- top-alt:auto;\n\tmargin-right:0in;\n\tmso-margin-bottom-alt:auto;\n\tmargin-left:0in;\n\tfont-size:12.0pt;\n\tfont-family:\"Times New Roman\",serif;}\np.centered, li.centered, div.centered\n\t{mso-style-name:centered;\n\tmso-margin-top-alt:auto;\n\tmargin-ri ght:0in;\n\tmso-margin-bottom-alt:auto;\n\tmargin-left:0in;\n\tfont-size:12.0pt;\n\tfont-family:\"Times New Roman\",serif;}\nspan .EmailStyle23\n\t{mso-style-type:personal-reply;\n\tfont-family:\"Calibri\",sans-serif;\n\tcolor:#1F497D;}\n.MsoChpDefault\n\t{ms o-style-type:export-only;\n\tfont-size:10.0pt;}\n@page WordSection1\n\t{size:8.5in 11.0in;\n\tmargin:1.0in 1.0in 1.0in 1.0in;}\nd iv.WordSection1\n\t{page:WordSection1;}\n--></style>\n"
  }
  let(:inline_style_text_css) {
    '<style type="text/css">
      @font-face { font-family: "Lettera"; src: url("/assets/lineto-lettera-bold-354dbb116eafa08513143f125adaf4bf123d3c3873363bb47f537dcfea1e298d.woff") format("woff"); font-style: normal; font-weight: 400; }
      @font-face { font-family: "National"; src: url("/assets/NationalWeb-Black-827906c62bfc6a0498a21c48b2ea87fb1bbd69a69d92c52610bc1bdfc1bf8e6e.woff") format("woff"); font-style: normal; font-weight: 900; }
    </style>'
  }
  let(:gmail_quotes) {
    '<div class="gmail_quote">
      <div dir="ltr">
        On Tue, Dec 27, 2016 at 8:01 PM I Done This &lt;
        <a href="mailto:life-recorded@entry.idonethis.com">life-recorded@entry.idonethis.com</a>
        &gt; wrote:
        <br>
      </div>
    </div>'
  }

  # NOTE: stripped-html from Mailgun may have signature, which we need to parse out
  let(:mailgun_stripped_html_emailed_entries) {
    {
      'stripped-html' =>
        "<div>Html Entry #1</div>" +
        "<span> Imperfect Html Entry #1  </span>" +
        sender_sign_off +
        signature_pattern_1,
    }
  }

  let(:mailgun_stripped_html_emailed_entries_with_cdata) {
    {
      'stripped-html' =>
        html_cdata +
        "<div>Html Entry #1</div>" +
        "<span> Imperfect Html Entry #1  </span>" +
        sender_sign_off +
        signature_pattern_1,
    }
  }

  let(:mailgun_stripped_html_emailed_entries_with_inline_style) {
    {
      'stripped-html' =>
        "<div>Html Entry #1</div>" +
        "<span> Imperfect Html Entry #1  </span>" +
        inline_style_text_css +
        sender_sign_off +
        signature_pattern_1,
    }
  }

  let(:mailgun_stripped_html_emailed_entries_with_gmail_quotes) {
    {
      'stripped-html' =>
        "<div>Html Entry #1</div>" +
        "<span> Imperfect Html Entry #1  </span>" +
        gmail_quotes
    }
  }

  test 'prefix_based_entries? determine if entries are prefixed' do
    refute MailgunEmailedEntriesPresenter.prefix_based_entries?('Entry #1')
    refute MailgunEmailedEntriesPresenter.prefix_based_entries?(' Imperfect Entry #1')

    assert MailgunEmailedEntriesPresenter.prefix_based_entries?('* Prefixed Entry #1')
    assert MailgunEmailedEntriesPresenter.prefix_based_entries?('*Imperfect Prefixed Entry #1')

    assert MailgunEmailedEntriesPresenter.prefix_based_entries?(
      "- Prefixed Entry #1",
      prefix: '-')

    refute MailgunEmailedEntriesPresenter.prefix_based_entries?("<div>Html Entry #1</div>")
    refute MailgunEmailedEntriesPresenter.prefix_based_entries?("<span> Imperfect Html Entry #1  </span>")
  end

  test 'parse_text returns [] when input is nil' do
    assert_equal [], MailgunEmailedEntriesPresenter.parse_text(nil)
  end

  test 'parse_text by default returns array with entries separated by line breaks/newline' do
    assert_equal ['Entry #1', ' Imperfect Entry #1'],
      MailgunEmailedEntriesPresenter.parse_text(
        ['Entry #1', ' Imperfect Entry #1'].join("\r\n")
        )
    assert_equal ['Entry #1', ' Imperfect Entry #1'],
      MailgunEmailedEntriesPresenter.parse_text(
        ['Entry #1', ' Imperfect Entry #1'].join("\n")
        )
  end

  test 'parse_text with regex returns array with entries separated by regex' do
    assert_equal [
        ['Entry #1', ' Imperfect Entry #1'].join("+")
      ],
      MailgunEmailedEntriesPresenter.parse_text(
        ['Entry #1', ' Imperfect Entry #1'].join("+"))
    assert_equal ['Entry #1', ' Imperfect Entry #1'],
      MailgunEmailedEntriesPresenter.parse_text(
        ['Entry #1', ' Imperfect Entry #1'].join("+"),
        regex: '+')
  end

  test 'parse_stripped_text_with_prefix returns [] if stripped-text are not stripped text entries' do
    assert_equal [],
      MailgunEmailedEntriesPresenter.new(mailgun_stripped_text_emailed_entries).
        parse_stripped_text_with_prefix
  end

  test 'parse_stripped_text_with_prefix returns array of entries if stripped-text are prefixed email entries' do
    assert_equal ['Prefixed Entry #1', 'Imperfect Prefixed Entry #1'],
      MailgunEmailedEntriesPresenter.new(mailgun_stripped_text_prefixed_emailed_entries).
        parse_stripped_text_with_prefix
  end

  test 'parse_stripped_text_with_prefix returns array of entries when prefixed email entries have line breaks' do
    assert_equal ['Prefixed Entry #1', 'Prefixed Entry #1 And Split'],
      MailgunEmailedEntriesPresenter.new(mailgun_stripped_text_prefixed_emailed_split_entries).
        parse_stripped_text_with_prefix
  end

  test 'parse_stripped_text_with_prefix returns array of entries excluding sender sign offs, e.g., name, and signature' do
    assert_equal ['Prefixed Entry #1', 'Imperfect Prefixed Entry #1'],
      MailgunEmailedEntriesPresenter.new(
        mailgun_stripped_text_prefixed_emailed_entries_with_sender_sign_off_and_signature).
        parse_stripped_text_with_prefix
  end

  test 'parse_stripped_html returns array of entries and removing signature and sender signoff, e.g., name, etc.' do
    assert_equal ['Html Entry #1', 'Imperfect Html Entry #1'],
      MailgunEmailedEntriesPresenter.new(mailgun_stripped_html_emailed_entries).parse_stripped_html
  end

  test 'parse_stripped_html removes cdata, returns array of entries and removing signature and sender signoff, e.g., name, etc.' do
    assert_equal ['Html Entry #1', 'Imperfect Html Entry #1'],
      MailgunEmailedEntriesPresenter.new(mailgun_stripped_html_emailed_entries_with_cdata).parse_stripped_html
  end

  test 'parse_stripped_html removes inline styles, returns array of entries and removing signature and sender signoff, e.g., name, etc.' do
    assert_equal ['Html Entry #1', 'Imperfect Html Entry #1'],
      MailgunEmailedEntriesPresenter.new(mailgun_stripped_html_emailed_entries_with_inline_style).parse_stripped_html
  end

  test 'parse_stripped_html removes gmail quotes, returns array of entries and removing signature and sender signoff, e.g., name, etc.' do
    assert_equal ['Html Entry #1', 'Imperfect Html Entry #1'],
      MailgunEmailedEntriesPresenter.new(mailgun_stripped_html_emailed_entries_with_gmail_quotes).parse_stripped_html
  end

  # THIS is the start of the thought that perhaps we should have some more complete email examples.  It's certainly handy
  # to be able to add the json from Mailgun and create a failing test to fix
  describe '.parse_stripped_html' do
    describe 'gmail email with gmail_quotes' do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'gmail_with_gmail_quotes.json'))) }

      it 'parses the 10 entries in the email' do
        assert_equal 10, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe 'gmail email with gmail_extra' do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'gmail_with_gmail_extra.json'))) }

      it 'parses the 11 entries in the email' do
        assert_equal 11, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe 'gmail email with no gmail_quotes and just a replied to' do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'gmail_replied_to.json'))) }

      it "ignores text below 'I Done This wrote' and parses the 23 entries in the email" do
        assert_equal 23, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe 'gmail email with stripped signature' do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'gmail_with_stripped_signature.json'))) }

      it "ignores text below the stripped signature and parses the 6 entries in the email" do
        assert_equal 6, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "gmail email with stripped signature 'Sent from my BlackBerry'" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'gmail_with_stripped_signature_blackberry.json'))) }

      it "ignores text below the stripped signature and parses the 1 entry in the email" do
        assert_equal 1, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "AOL email with replied to and 'On Dec 27, 2016, at 5:32 AM, I Done This'" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'aol_replied_to.json'))) }

      it "ignores text below the 'On Dec 27, 2016, at 5:32 AM, I Done This' and parses the 5 entries in the email" do
        assert_equal 5, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "gmail email with replied to and no real way of determining where the entries finish" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'gmail_no_structure.json'))) }

      it "defaults back to using stripped-text and parses the 3 entries in the email" do
        assert_equal 3, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "gmail email with replied to and 'On Dec 23, 2016, 5:02 PM -0800, I Done This" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'gmail_replied_to_2.json'))) }

      it "ignores text below the 'On Dec 23, 2016, 5:02 PM -0800, I Done This' and parses the 14 entries in the email" do
        assert_equal 14, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "hotmail email with main_sig" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'hotmail_with_main_sig.json'))) }

      it "parses the 1 entry in the email" do
        assert_equal 1, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "hotmail email with 'From:'" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'hotmail.json'))) }

      it "ignores text below the 'From:' and parses the 3 entries in the email" do
        assert_equal 3, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "MS exchange email with 'Take 30 seconds ...'" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'ms_exchange.json'))) }

      it "ignores text below the 'Take 30 seconds ...' and parses the 1 entry in the email" do
        assert_equal 1, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "Outlook email with 'Sent from Mail for Windows 10'" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'outlook.json'))) }

      it "ignores text below the 'Sent from Mail for Windows 10 and parses the 3 entries in the email" do
        assert_equal 3, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "MS Office email with 'Check-in\non'" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'ms_office.json'))) }

      it "ignores text below the 'Check-in on' and parses the 1 entry in the email" do
        assert_equal 1, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "MS Office email with 'If you want to add anything'" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'ms_office_2.json'))) }

      it "ignores text below the 'If you want to add anything' and parses the 1 entry in the email" do
        assert_equal 1, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "Email with special characters in signature" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'gmail_special_sig.json'))) }

      it "parses the 1 entry in the email" do
        assert_equal 1, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "IBM email with underscore line as signature line" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'ibm_email.json'))) }

      it "parses the 2 entries in the email" do
        assert_equal 2, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "email with signature and new lines" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'email_with_stripped_signature_and _newlines.json'))) }

      it "parses the 23 entries in the email" do
        assert_equal 23, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "Yahoo email with yahoo_quoted" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'yahoo_with_yahoo_quoted.json'))) }

      it "parses the 19 entries in the email" do
        assert_equal 19, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "gmail email with entries containing urls" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'gmail_entries_with_urls.json'))) }

      it "parses the 4 entries in the email" do
        assert_equal 4, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end

    describe "outlook email with entries containing urls" do
      let (:file) { JSON.parse(File.read(Rails.root.join('test', 'fixtures', 'inbound_emails', 'outlook_entries_with_urls.json'))) }

      it "parses the 4 entries in the email" do
        assert_equal 4, MailgunEmailedEntriesPresenter.new(file).parse_stripped_html.length
      end
    end
  end

end
