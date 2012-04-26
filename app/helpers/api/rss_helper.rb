module Api::RssHelper
  include Api::TireHelper

  def collection_rss(xml, collection, results)
    parents = parents_as_hash results

    xml.rss rss_specification do
      xml.channel do
        xml.title collection.name
        xml.lastBuildDate collection.updated_at.rfc822
        xml.atom :link, rel: :previous, href: url_for(params.merge page: results.previous_page, only_path: false) if results.previous_page
        xml.atom :link, rel: :next, href: url_for(params.merge page: results.next_page, only_path: false) if results.next_page

        results.each do |result|
          site_item_rss xml, result, parents
        end
      end
    end
  end

  def site_item_rss(xml, result, parents = nil)
    source = result['_source']
    parents ||= parents_as_hash([result])

    xml.item do
      xml.title source['name']
      xml.pubDate Site.parse_date(source['updated_at']).rfc822
      xml.link api_site_url(source['id'], format: :rss)
      xml.guid api_site_url(source['id'], format: :rss)

      if source['location']
        xml.geo :lat, source['location']['lat']
        xml.geo :long, source['location']['lon']
      end

      xml.rm :properties do
        source['properties'].each do |code, values|
          Array(values).each do |value|
            property_rss xml, code, value
          end
        end
      end

      Array(source['parent_ids']).each do |parent_id|
        group_rss xml, parents[parent_id]
      end
    end
  end

  def activities_rss(xml, activities)
    xml.rss rss_specification do
      xml.channel do
        xml.title 'Activity'
        xml.lastBuildDate activities.first.created_at.rfc822
        activities.each do |activity|
          activity_rss xml, activity
        end
      end
    end
  end

  def activity_rss(xml, activity)
    xml.item do
      xml.title "[In collection '#{activity.collection.name}' by user '#{activity.user.display_name}'] #{activity.description} "
      xml.pubDate activity.created_at.rfc822
      xml.guid activity.id
    end
  end

  def rss_specification
    {
      'version'    => "2.0",
      'xmlns:geo'  => "http://www.w3.org/2003/01/geo/wgs84_pos#",
      'xmlns:rm'   => "http://resourcemap.instedd.org/api/1.0",
      'xmlns:atom' => "http://www.w3.org/2005/Atom"
    }
  end

  private

  def property_rss(xml, code, value)
    xml.__send__ "rm:#{code}", value
  end

  def group_rss(xml, group)
    xml.rm :group, level: group.level do
      xml.rm :id, group.id
      xml.rm :name, group.name
    end
  end
end
