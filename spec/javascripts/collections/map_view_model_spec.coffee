describe 'Collection', ->
  beforeEach ->
    window.runOnCallbacks 'collections'

    @collection = new Collection id: 1
    window.model = new MainViewModel [@collection]
    @model = window.model

  describe 'MapViewModel', ->
    beforeEach ->
      @marker = new google.maps.Marker
      spyOn(@marker, 'setIcon')
      spyOn(@marker, 'setShadow')
      @model = window.model

    describe 'Sites Query Params', ->
      beforeEach ->
        sw = new google.maps.LatLng(34, 0, false)
        ne = new google.maps.LatLng(22, 10, false)
        @bounds = new google.maps.LatLngBounds(sw, ne)

        field = new Field { id: 1, code: 'admu', name: 'Admin Unit', kind: 'select_one', writeable: true }
        col_hierarchy = new CollectionHierarchy(@collection, field)
        @hierarchyItem = new HierarchyItem(col_hierarchy, field, { id: 1, label: 'group 1', sub: [{id: 2, label: 'group 2'}]})

      it 'should include selected_hierarchy_id id in sites query', ->
        query_before = @model.generateQueryParams(@bounds, [1], 1)

        expect(query_before.selected_hierarchy_id).toBe(undefined)

        @model.selectHierarchy(@hierarchyItem)
        query = @model.generateQueryParams(@bounds, [1], 1)

        expect(query.selected_hierarchy_id).toEqual 1

