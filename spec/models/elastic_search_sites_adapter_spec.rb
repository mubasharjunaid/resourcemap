require 'spec_helper'

describe ElasticSearchSitesAdapter do
  it "adapts one site", :focus => true do
    listener = mock('listener')
    listener.should_receive(:add).with :id => 181984, :lat => -37.55442222700955, :lng => 136.5797882218185, :parent_ids => [10, 20, 30]

    adapter = ElasticSearchSitesAdapter.new listener
    adapter.parse %(
      {
        "took" : 20,
        "timed_out" : false,
        "_shards" : {
          "total" : 55,
          "successful" : 55,
          "failed" : 0
        },
        "hits" : {
          "total" : 4,
          "max_score" : 1.0,
          "hits" : [ {
            "_index" : "collection_63",
            "_type" : "site",
            "_id" : "181984",
            "_score" : 1.0, "_source" : {"id":181984,"type":"site","location":{"lat":-37.55442222700955,"lon":136.5797882218185},"properties":{"beds":84,"vaccines":75,"patients":61},"parent_ids":[10,20,30]}
          } ]
        }
      }
    )
  end

  it "adapts one site without conflicting on properties" do
    listener = mock('listener')
    listener.should_receive(:add).with :id => 181984, :lat => -37.55442222700955, :lng => 136.5797882218185, :parent_ids => []

    adapter = ElasticSearchSitesAdapter.new listener
    adapter.parse %(
      {
        "took" : 20,
        "timed_out" : false,
        "_shards" : {
          "total" : 55,
          "successful" : 55,
          "failed" : 0
        },
        "hits" : {
          "total" : 4,
          "max_score" : 1.0,
          "hits" : [ {
            "_index" : "collection_63",
            "_type" : "site",
            "_id" : "181984",
            "_score" : 1.0, "_source" : {"id":181984,"type":"site","location":{"lat":-37.55442222700955,"lon":136.5797882218185},"properties":{"properties":5,"beds":84,"vaccines":75,"patients":61,"id":1,"lat":2,"lon":3}}
          } ]
        }
      }
    )
  end

  it "adapts two sites" do
    listener = mock('listener')
    listener.should_receive(:add).with :id => 181984, :lat => -37.55442222700955, :lng => 136.5797882218185, :parent_ids => []
    listener.should_receive(:add).with :id => 181985, :lat => -47.55442222700955, :lng => 137.5797882218185, :parent_ids => []

    adapter = ElasticSearchSitesAdapter.new listener
    adapter.parse %(
      {
        "took" : 20,
        "timed_out" : false,
        "_shards" : {
          "total" : 55,
          "successful" : 55,
          "failed" : 0
        },
        "hits" : {
          "total" : 4,
          "max_score" : 1.0,
          "hits" : [ {
            "_index" : "collection_63",
            "_type" : "site",
            "_id" : "181984",
            "_score" : 1.0, "_source" : {"id":181984,"type":"site","location":{"lat":-37.55442222700955,"lon":136.5797882218185},"properties":{"beds":84,"vaccines":75,"patients":61}}
          }, {
            "_index" : "collection_63",
            "_type" : "site",
            "_id" : "181984",
            "_score" : 1.0, "_source" : {"id":181985,"type":"site","location":{"lat":-47.55442222700955,"lon":137.5797882218185},"properties":{"beds":84,"vaccines":75,"patients":61}}
          } ]
        }
      }
    )
  end

  context ElasticSearchSitesAdapter::SkipIdListener do
    it "skips id" do
      listener = mock('listener')
      listener.should_not_receive(:add)
      skip = ElasticSearchSitesAdapter::SkipIdListener.new listener, 1
      skip.add :id => 1
    end

    it "doesn't skip id" do
      listener = mock('listener')
      listener.should_receive(:add).with :id => 2
      skip = ElasticSearchSitesAdapter::SkipIdListener.new listener, 1
      skip.add :id => 2
    end
  end
end