require 'spec_helper'

describe CSDContactMapping do 
	describe 'names' do
		it 'is empty' do
			m = CSDContactMapping.new 'Contact', []
			m.names.should be_empty
		end

		it 'has two names' do
			name1 = Field::TextField.make.csd_contact_name! "Contact 1", "Name 1"
			name2 = Field::TextField.make.csd_contact_name! "Contact 1", "Name 2"

			m = CSDContactMapping.new "Contact 1", [name1, name2]

			m.names.should have(2).items

			m.names[0].class.should be(CSDNameMapping)
			m.names[1].class.should be(CSDNameMapping)
		end
	end

	describe 'addresses' do
		it 'is empty' do
			m = CSDContactMapping.new 'Contact', []
			m.addresses.should be_empty
		end

		it 'has two addresses' do
			address1 = Field::TextField.make.csd_contact_address! "Contact 1", "Address 1"
			address2 = Field::TextField.make.csd_contact_address! "Contact 1", "Address 2"

			m = CSDContactMapping.new("Contact 1", [address1, address2])

			m.addresses.should have(2).items

			m.addresses[0].class.should be(CSDAddressMapping)
			m.addresses[1].class.should be(CSDAddressMapping)
		end
	end
end