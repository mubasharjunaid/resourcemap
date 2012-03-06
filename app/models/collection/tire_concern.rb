module Collection::TireConcern
  extend ActiveSupport::Concern

  included do
    after_create :create_index
    after_destroy :destroy_index
  end

  def create_index
    index.create({
      :refresh => true,
      :mappings => {
        :site => {
          :properties => {
            :location => {
              :type => :geo_point
            }
          }
        }
      }
    })
  end

  def destroy_index
    index.delete
  end

  def index
    @index ||= self.class.index(id)
  end

  def index_name
    self.class.index_name(id)
  end

  def new_map_search
    MapSearch.new id
  end

  def new_tire_search
    search = Tire::Search::Search.new index_name
    search.filter :type, {:value => :site}
    search
  end

  module ClassMethods
    def index_name(id)
      "collection_#{id}"
    end

    def index(id)
      ::Tire::Index.new index_name(id)
    end
  end
end
