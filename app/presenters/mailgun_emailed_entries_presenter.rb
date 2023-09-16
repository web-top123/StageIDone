class MailgunEmailedEntriesPresenter
  PREFIXES = {
    star: '*',
  }
  
  # If input contains only entries, i.e., sender signoffs and signatures
  # has been removed then sanitize entries and break them up
  def self.parse_text(text, regex: /\r?\n/)
    sanitized = text.present? ?
      ActionView::Base.full_sanitizer.sanitize(text) :
      ''
    sanitized.split(regex)
  end

  def self.remove_html_quotes!(nokogiri_doc)
    nokogiri_doc.css('.gmail_quote').remove
    nokogiri_doc.css('.gmail_extra').remove
    nokogiri_doc.css('.yahoo_quoted').remove
    nokogiri_doc.css('.main_sig').remove
  end

  def self.remove_html_comments!(nokogiri_doc)
    text_nodes = nokogiri_doc.search('//text()')
    text_nodes.each { |text_node_elem| text_node_elem.remove if text_node_elem.text.match(/\A<!--.*-->\Z/m) }
  end

  def self.remove_style_elements!(nokogiri_doc)
    nokogiri_doc.search('//style').remove
  end

  def self.remove_html_signature!(nokogiri_doc, signature)
    # Look for signature
    text_nodes = nokogiri_doc.search('//text()')
    unwanted_text_nodes = text_nodes.drop_while { |node_elem| node_elem.text.match(/^#{Regexp.quote(signature)}/).nil? }
    unwanted_text_nodes.map(&:remove)
  end

  def self.remove_html_reply!(nokogiri_doc)
    # Look for anything with 'I Done This wrote:''
    text_nodes = nokogiri_doc.search('//text()')

    unwanted_text_nodes = text_nodes.drop_while { |node_elem| node_elem.text.match(/I Done This wrote:/).nil? }
    unwanted_text_nodes.map(&:remove)

    unwanted_text_nodes = text_nodes.drop_while { |node_elem| node_elem.text.match(/On (...*) I Done This/).nil? }
    unwanted_text_nodes.map(&:remove)

    unwanted_text_nodes = text_nodes.drop_while { |node_elem| node_elem.text.match(/^From:/).nil? }
    unwanted_text_nodes.map(&:remove)

    unwanted_text_nodes = text_nodes.drop_while { |node_elem| node_elem.text.match(/^Sent from/).nil? }
    unwanted_text_nodes.map(&:remove)

    unwanted_text_nodes = text_nodes.drop_while { |node_elem| node_elem.text.match(/^Check-in\n on/).nil? }
    unwanted_text_nodes.map(&:remove)

    unwanted_text_nodes = text_nodes.drop_while { |node_elem| node_elem.text.match(/^Take 30 seconds to do a quick status update for your team/).nil? }
    unwanted_text_nodes.map(&:remove)

    unwanted_text_nodes = text_nodes.drop_while { |node_elem| node_elem.text.match(/^If you want to add anything/).nil? }
    unwanted_text_nodes.map(&:remove)

    unwanted_text_nodes = text_nodes.drop_while { |node_elem| node_elem.text.match(/^____/).nil? }
    unwanted_text_nodes.map(&:remove)
  end

  def self.unwrap_anchors!(nokogiri_doc)
    nokogiri_doc.search('//*[a]').each do |text_node|
      text_node.replace ActionController::Base.helpers.strip_links(text_node.to_s)
    end
  end

  # Heuristic to determine if entries in email are prefixed
  def self.prefix_based_entries?(input, prefix: PREFIXES[:star])
    possible_entries = self.parse_text(input).select { |e| e.present? }
    return possible_entries[0].present? && (possible_entries[0].strip[0] == prefix)
  end

  # Heuristic to remove sender signoff/signature from prefixed email entries
  def self.strip_signature_from_prefixed_emailed_entries(text, prefix: PREFIXES[:star])
    if self.prefix_based_entries?(text, prefix: prefix)
      # Last prefixed line may include signature
      prefixed_lines = self.parse_text(text, regex: prefix)
      last_prefixed_line = prefixed_lines[-1]

      # Use part of the line before double line breaks, i.e.,
      # treating anything after as signoff/signature
      match_arr = last_prefixed_line.match(/(.*?)\r?\n\r?\n/)
      last_line_segment_before_double_slash_n = match_arr.present? ? match_arr[1] : last_prefixed_line
      prefixed_lines[-1] = last_line_segment_before_double_slash_n
      text_without_signature = prefixed_lines.join(prefix)
    else
      text_without_signature = text
    end
    text_without_signature
  end

  # params - {Hash} Params that Mailgun forwards to us 
  #          for inbound email
  def initialize(params)
    @params = params
  end

  # Parse entries that are prefixed
  def parse_stripped_text_with_prefix(prefix: PREFIXES[:star])
    stripped_text = @params['stripped-text']
    if self.class.prefix_based_entries?(stripped_text, prefix: prefix)
      text_without_signature = self.class.
                                 strip_signature_from_prefixed_emailed_entries(
                                   stripped_text, prefix: prefix)
      entries = self.class.
                  parse_text(text_without_signature, regex: prefix).
                  map(&:strip).
                  select { |e| e.present? }.
                  map { |e| e.gsub(/\r?\n/, ' ') }
    else
      entries = []
    end
    entries
  end

  def signature
    signature = @params['stripped-signature']
    signature.blank? ? "--" : signature.split(/\r?\n/).first
  end

  # Get entries from Mailgun's 'stripped-text'
  # NOTE:
  # * Some clients like gmail inserts "\n" based on the sender's email
  #   viewport size so that the email can be presented to recipient
  #   as seen by sender. 'stripped-text' contains this additional
  #   "\n", which may result in in a single entry being wrongly broken 
  #   up into multiple entries
  def parse_stripped_text
    # Use EmailReplyParse mainly to strip out signature
    parsed_body = EmailReplyParser.parse_reply(@params['stripped-text'])
    self.class.parse_text(parsed_body)
  end

  # Get entries from Mailgun's 'stripped-html' using structure
  # of document as heuristics.
  # NOTE: Previously we parsed the stripped-text as shown:
  #   parsed_body = EmailReplyParser.parse_reply(params['stripped-text'])
  # See https://github.com/idonethis/idt-two/issues/698
  # Email client(?) will add line-breaks based on the user view 
  # resulting in line-breaks between single entry, which we will wrongly parse
  # as multiple entries when it should be a single entry
  def parse_stripped_html
    parsed_html = Nokogiri::HTML(@params['stripped-html'])

    self.class.remove_html_quotes!(parsed_html)
    self.class.remove_html_comments!(parsed_html)
    self.class.remove_style_elements!(parsed_html)
    self.class.remove_html_signature!(parsed_html, signature)
    self.class.remove_html_reply!(parsed_html)
    self.class.unwrap_anchors!(parsed_html)

    # Get all blobs of text and join them
    entries = parsed_html.search('//text()').map(&:text).map { |text_elem|
      text_elem.present? ?
        ActionView::Base.full_sanitizer.sanitize(text_elem.strip) :
        ''
    }.reject { |elem| elem.blank? }

    if entries.length < 50 # at this point parsing the HTML has probably failed
      entries
    else
      parse_stripped_text
    end
  end
end
