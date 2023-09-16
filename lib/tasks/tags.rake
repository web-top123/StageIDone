namespace :tags do
  desc "Deduplicate tags with the same name"
  task dedupe: :environment do
    # First make sure all tags are downcased
    Tag.all.each do |tag|
      tag.update_attribute(:name, tag.name.downcase)
    end
    Tag.uniq.pluck(:name).each do |tag_name|
      tags = Tag.where(name: tag_name).all
      if tags.length > 1
        real_tag = tags.to_a.shift
        tags.each do |fake_tag|
          fake_tag.entry_tags.update_all(tag_id: real_tag.id)
          fake_tag.destroy
        end
      end
    end
  end

end
