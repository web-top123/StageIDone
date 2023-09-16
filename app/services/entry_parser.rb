class EntryParser
  class << self
    include Twitter::Extractor
    # Default CSS class for auto-linked lists
    DEFAULT_LIST_CLASS = "url link-list-slug".freeze
    # Default CSS class for auto-linked usernames
    DEFAULT_USERNAME_CLASS = "url link-username".freeze
    # Default CSS class for auto-linked hashtags
    DEFAULT_HASHTAG_CLASS = "url link-hashtag".freeze
    # Default CSS class for auto-linked cashtags
    DEFAULT_CASHTAG_CLASS = "url link-cashtag".freeze

    # Default URL base for auto-linked usernames
    DEFAULT_USERNAME_URL_BASE = "/users/".freeze
    # Default URL base for auto-linked lists
    DEFAULT_LIST_URL_BASE = "/users".freeze
    # Default URL base for auto-linked hashtags
    DEFAULT_HASHTAG_URL_BASE = "/tags/".freeze
    # Default URL base for auto-linked cashtags
    DEFAULT_CASHTAG_URL_BASE = "#!tag?q=%24".freeze

    # Default attributes for invisible span tag
    DEFAULT_INVISIBLE_TAG_ATTRS = "style='position:absolute;left:-9999px;'".freeze

    DEFAULT_OPTIONS = {
      :list_class     => DEFAULT_LIST_CLASS,
      :username_class => DEFAULT_USERNAME_CLASS,
      :hashtag_class  => DEFAULT_HASHTAG_CLASS,
      :cashtag_class  => DEFAULT_CASHTAG_CLASS,

      :username_url_base => DEFAULT_USERNAME_URL_BASE,
      :list_url_base     => DEFAULT_LIST_URL_BASE,
      :hashtag_url_base  => DEFAULT_HASHTAG_URL_BASE,
      :cashtag_url_base  => DEFAULT_CASHTAG_URL_BASE,

      :invisible_tag_attrs => DEFAULT_INVISIBLE_TAG_ATTRS
    }.freeze

    def parse(entry)
      sanitizer = Rails::Html::FullSanitizer.new
      sanitized = sanitizer.sanitize(entry.body.gsub(/^(\[[\sx]*)\]/, ''))
      sanitized.gsub("\n", "<br/>")
    end

    # Produces an HTML output string with all of the parsed links we want
    def auto_link(entry)
      parsed   = parse(entry)
      entities = extract_entities(parsed)
      auto_link_entities_wthout_cmmnt(entry, parsed, entities)
    end

    def auto_link_comment(reaction) # should probably live in a CommentParser
      # This will break if we allow comments on comments, then we need to rethink how
      # we do this
      if reaction.reaction_type == 'comment' && reaction.reactable.class == Entry
        sanitizer = Rails::Html::FullSanitizer.new
        sanitized = sanitizer.sanitize(reaction.body)
        entities = extract_entities(sanitized)
        auto_link_entities(reaction.reactable, reaction, sanitized, entities)
      else
        reaction.body
      end
    end

    def auto_link_entities_wthout_cmmnt(entry, text, entities)
      return text if entities.empty?

      # TODO: This is likely inefficient, needs caching or preloading
      if entry.team.personal?
        org_hash = nil
        personal = true
      else
        org_hash = entry.team.organization.hash_id
        personal = false
      end

      Twitter::Rewriter.rewrite_entities(text.dup, entities) do |entity, _chars|
        if entity[:url]
          image_or_link(entity[:url])
        elsif entity[:hashtag]
          if personal
            "<a href=\"/t/#{ entry.team.hash_id }/tags/#{entity[:hashtag]}\">##{entity[:hashtag]}</a>"
          else
            "<a href=\"/o/#{org_hash}/tags/#{entity[:hashtag]}\">##{entity[:hashtag]}</a>"
          end
        elsif entity[:screen_name]
          if !personal && user = entry.team.active_users.where(go_by_name: entity[:screen_name]).first
            "<a href=\"/o/#{org_hash}/u/#{user.hash_id}\">@#{entity[:screen_name]}</a>"
          else
            "@#{entity[:screen_name]}"
          end
        end
      end
    end

    def auto_link_entities(entry,comment , text, entities)
      return text if entities.empty?

      # TODO: This is likely inefficient, needs caching or preloading
      if entry.team.personal?
        org_hash = nil
        personal = true
      else
        org_hash = entry.team.organization.hash_id
        personal = false
      end

      Twitter::Rewriter.rewrite_entities(text.dup, entities) do |entity, _chars|
        if entity[:url]
          image_or_link(entity[:url])
        elsif entity[:hashtag]
          if personal
            "<a href=\"/t/#{ entry.team.hash_id }/tags/#{entity[:hashtag]}\">##{entity[:hashtag]}</a>"
          else
            if comment
              "<a href=\"/o/#{org_hash}/tags/#{entity[:hashtag]}/?comment_id=#{comment.id}\">##{entity[:hashtag]}</a>"
            else
              "<a href=\"/o/#{org_hash}/tags/#{entity[:hashtag]}\">##{entity[:hashtag]}</a>"
            end
          end
        elsif entity[:screen_name]
          if !personal && user = entry.team.active_users.where(go_by_name: entity[:screen_name]).first
            "<a href=\"/o/#{org_hash}/u/#{user.hash_id}\">@#{entity[:screen_name]}</a>"
          else
            "@#{entity[:screen_name]}"
          end
        end
      end
    end

    # This is overridden from Twitter::Extractor because we don't want cashtags
    def extract_entities(text, &block)
      entities = extract_urls_with_indices(text, {extract_url_without_protocol: true}) +
                 extract_hashtags_with_indices(text, :check_url_overlap => false) +
                 extract_mentions_or_lists_with_indices(text)
      return [] if entities.empty?
      entities = remove_overlapping_entities(entities)
      entities.each(&block) if block_given?
      entities
    end

    def image_or_link(entity_link)
      entity_url = entity_link.length > 30 ? "#{entity_link[0,25]}..." : entity_link
      page_path = Addressable::URI.heuristic_parse(entity_link).to_s
      begin
        if ['.jpg','.png', '.gif', '.jpeg'].any? { |image_ext| page_path.downcase.include?(image_ext) }
          "<a href=\"#{page_path}\">#{entity_url}</a>
          <div class='entry-img'>
            <img src='#{page_path}' style='max-width:266px; max-height:200px;'>
          </div>"
        else
          "<a href=\"#{page_path}\">#{entity_url}</a>"
        end
      rescue
        "<a href=\"#{page_path}\">#{entity_url}</a>"
      end
    end
  end
end
