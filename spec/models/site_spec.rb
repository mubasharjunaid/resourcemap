require 'spec_helper'

describe Site do
  it { should belong_to :collection }
  it { should belong_to :parent }

  it "stores nil hierarchy for root" do
    site = Site.make
    site.hierarchy.should be_nil
  end

  it "stores hierarchy" do
    collection = Collection.make
    site1 = collection.sites.make
    site2 = collection.sites.make :parent_id => site1.id
    site3 = collection.sites.make :parent_id => site2.id

    site1.reload
    site1.hierarchy.should be_nil

    site2.reload
    site2.hierarchy.should eq("#{site1.id}")

    site3.reload
    site3.hierarchy.should eq("#{site1.id},#{site2.id}")
  end
end