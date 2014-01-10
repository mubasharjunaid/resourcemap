class LayersController < ApplicationController

  before_filter :fix_field_config, only: [:create, :update]

  authorize_resource :layer, :decent_exposure => true, :except => :create

  expose(:layers) {
    authorize! :read, collection

    if !current_user_snapshot.at_present? && collection then
      collection.layer_histories.accessible_by(current_ability).at_date(current_user_snapshot.snapshot.date)
    else
      collection.layers.accessible_by(current_ability)
    end
  }

  expose(:layer)

  def index
    layers # signal that layers will be used on this page (loaded by ajax later)
    respond_to do |format|
      format.html do
        show_collection_breadcrumb
        add_breadcrumb "Properties", collection_path(collection)
        add_breadcrumb "Layers", collection_layers_path(collection)
      end
      if current_user_snapshot.at_present?
        format.json { render_json layers.includes(:fields).as_json(include: :fields) }
      else
        format.json {
          render_json layers
            .includes(:field_histories)
            .where("field_histories.valid_since <= :date && (:date < field_histories.valid_to || field_histories.valid_to is null)", date: current_user_snapshot.snapshot.date)
            .as_json(include: :field_histories)
          }
      end
    end
  end

  def create
    layer = layers.new params[:layer]
    layer.user = current_user
    authorize! :create, layer
    layer.save!
    current_user.layer_count += 1
    current_user.update_successful_outcome_status
    current_user.save!
    render_json layer.as_json(include: :fields)
  end

  def update
    # FIX: For some reason using the exposed layer here results in duplicated fields being created
    layer = collection.layers.find params[:id]
    fix_layer_fields_for_update(layer)
    layer.user = current_user
    layer.update_attributes! params[:layer]
    layer.reload
    render_json layer.as_json(include: :fields)
  end

  def set_order
    # cancan layer is 'readonly' :S
    # https://github.com/ryanb/cancan/issues/357
    layer = collection.layers.find(params[:id],  :readonly => false)

    layer.user = current_user
    layer.update_attributes! ord: params[:ord]
    render_json layer
  end

  def destroy
    layer.user = current_user
    layer.destroy
    head :ok
  end

  def decode_hierarchy_csv
    @hierarchy = collection.decode_hierarchy_csv_file(params[:file].path)
    @hierarchy_errors = collection.generate_error_description_list(@hierarchy)
    render layout: false
  end

  private

  # The options come as a hash insted of a list, so we convert the hash to a list
  # Also fix hierarchy in the same way.
  def fix_field_config
    if params[:layer] && params[:layer][:fields_attributes]
      params[:layer][:fields_attributes].each do |field_idx, field|
        if field[:config]
          if field[:config][:options]
            field[:config][:options] = field[:config][:options].values
            field[:config][:options].each { |option| option['id'] = option['id'].to_i }
          end
          field[:config][:next_id] = field[:config][:next_id].to_i if field[:config][:next_id]
          if field[:config][:hierarchy]
            field[:config][:hierarchy] = field[:config][:hierarchy].values
            sanitize_items field[:config][:hierarchy]
          end
        end
      end
    end
  end

  def sanitize_items(items)
    items.each do |item|
      if item[:sub]
        item[:sub] = item[:sub].values
        sanitize_items item[:sub]
      end
    end
  end

  # Instead of sending the _destroy flag to destroy fields (complicates things on the client side code)
  # we check which are the current fields ids, which are the new ones and we delete those fields
  # whose ids don't show up in the new ones and then we add the _destroy flag.
  #
  # That way we preserve existing fields and we can know if their codes change, to trigger a reindex
  def fix_layer_fields_for_update(layers)
    fields = layer.fields

    fields_ids = fields.map(&:id).compact
    new_ids = params[:layer][:fields_attributes].values.map { |x| x[:id].try(:to_i) }.compact
    removed_fields_ids = fields_ids - new_ids

    max_key = params[:layer][:fields_attributes].keys.map(&:to_i).max
    max_key += 1

    removed_fields_ids.each do |id|
      params[:layer][:fields_attributes][max_key.to_s] = {id: id, _destroy: true}
      max_key += 1
    end

    params[:layer][:fields_attributes] = params[:layer][:fields_attributes].values
  end
end
