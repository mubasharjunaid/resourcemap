module Field::CSDApiConcern
  extend ActiveSupport::Concern

  def csd_coded_type!(coding_schema)
  	put_in_metadata "CSDType", "codedType"
  	put_in_metadata "codingSchema", coding_schema
  	save!
  	self
  end

  def csd_oid!
  	put_in_metadata "CSDType", "oid"
  	save!
  	self
  end

  def csd_contact!(contact_code)
    put_in_metadata "CSDType", "contact"
    put_in_metadata "CSDCode", contact_code
    save!
    self
  end

  def csd_contact_common_name!(contact_code, contact_name, language)
    put_in_metadata "CSDType", "contact"
    put_in_metadata "CSDCode", contact_code
    put_in_metadata "CSDContactName", contact_name
    put_in_metadata "CSDComponent", "commonName"
    put_in_metadata "language", language
    save!
    self
  end

  def csd_contact_name!(contact_code, contact_name)
    put_in_metadata "CSDType", "contact"
    put_in_metadata "CSDCode", contact_code
    put_in_metadata "CSDContactName", contact_name
    save!
    self
  end

  def csd_forename!(contact_code, contact_name)
    csd_contact_name_child! contact_code, contact_name, "forename"
  end

  def csd_surname!(contact_code, contact_name)
    csd_contact_name_child! contact_code, contact_name, "surname"
  end

  def csd_contact_name_child!(contact_code, contact_name, element_name)
    put_in_metadata "CSDType", "contact"
    put_in_metadata "CSDCode", contact_code
    put_in_metadata "CSDContactName", contact_name
    put_in_metadata "CSDComponent", element_name
    save!
    self
  end

  def csd_address_line!(contact_code, address_code, component)
    put_in_metadata "CSDType", "contact"
    put_in_metadata "CSDCode", contact_code
    put_in_metadata "CSDContactAddress", address_code
    put_in_metadata "CSDContactAddressLine", component
    save!
    self
  end

  def csd_contact_address!(contact_code, address_code)
    put_in_metadata "CSDType", "contact"
    put_in_metadata "CSDCode", contact_code
    put_in_metadata "CSDContactAddress", address_code
    save!
    self
  end

  def csd_status?
  	csd_declared_type? "status"
  end

  def csd_language?
  	csd_declared_type? "language"
  end

  def csd_contact_point?
  	csd_declared_type? "contactPoint"
  end

  def csd_address?
  	csd_declared_type? "address"
  end

  def csd_other_name?
  	csd_declared_type? "otherName"
  end

  def csd_facility_type?
  	csd_declared_type?("facilityType") && in_metadata?("OptionList")
  end

  def csd_coded_type?
  	csd_declared_type?("codedType") && in_metadata?("codingSchema")
  end

  def csd_oid?
  	csd_declared_type? "oid" 
  end

  def csd_other_id?
    self.is_a?(Field::IdentifierField) && !csd_oid?
  end

  def csd_declared_type?(type)
  	!self.metadata.blank? && csd_type == type
  end

  def csd_contact?
    csd_declared_type?("contact") && in_metadata?("CSDCode")
  end

  def csd_contact_name?
    csd_declared_type?("contact") && 
    in_metadata?("CSDCode") &&
    in_metadata?("CSDContactName")
  end

  def csd_contact_common_name?
    csd_declared_type?("contact") && 
    in_metadata?("CSDCode") &&
    metadata_value_for("CSDComponent") == "commonName" &&
    in_metadata?("language")
  end

  def csd_forename?
    in_metadata?("CSDContactName") &&
    metadata_value_for("CSDComponent") == "forename"
  end

  def csd_surname?
    in_metadata?("CSDContactName") &&
    metadata_value_for("CSDComponent") == "surname"
  end

  def csd_address_line?
    in_metadata?("CSDContactAddressLine")
  end

  def csd_contact_address?
    in_metadata?("CSDContactAddress")
  end

  def csd_type
  	metadata_value_for "CSDType"
  end

  #These methods should either:
  # A) go away once we change the data structure to represent metadata, or at least
	# B) move to Field::Field
  def metadata_value_for(metadata_key)
    if in_metadata?(metadata_key)
      metadata_entry = self.metadata.values.find{|element| element["key"] == metadata_key}
      metadata_entry["value"]
    end
  end

  def in_metadata?(metadata_key)
    !self.metadata.values.find{|element| element["key"] == metadata_key}.nil?
  end

 	#This method in particular is really weird due to the metadata representation we're using.
  #We really need to refactor that.
  def put_in_metadata(key, value)
  	self.metadata = {} if self.metadata.blank?

  	entry = self.metadata.find {|k,v| v[key]}
  	entry = ["#{self.metadata.keys.length}", {}] if !entry
  	self.metadata[entry[0]] = { "key" => key, "value" => value }
  end
end