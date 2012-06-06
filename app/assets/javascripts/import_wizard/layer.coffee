onImportWizard ->
  class @Layer
    constructor: (data) ->
      @id = data.id
      @name = data.name
      @fields = $.map(data.fields, (x) -> new Field(x))

    findField: (id) =>
      (field for field in @fields when field.id == id)[0]
