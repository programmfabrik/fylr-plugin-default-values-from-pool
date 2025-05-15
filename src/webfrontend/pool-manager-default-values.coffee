class ez5.PoolManagerDefaultValues extends ez5.PoolPlugin

  findFieldSchema: (mask, fieldnameDatamodel) ->
    # loop through all masks and find the one with the name fieldnameDatamodel == __all_fields
    fieldSchema = false
    maskFields = mask
    if mask?.mask?.fields
      maskFields = mask.mask.fields
    for maskEntry in maskFields
      # it is field or linkfield --> ready
      if maskEntry.kind == 'field' || maskEntry.kind == 'link'
        if maskEntry._full_name == fieldnameDatamodel
          fieldSchema = maskEntry
          return fieldSchema
      # it is a linked-table --> recursive call
      if maskEntry.kind == 'linked-table'
        # recursive call
        fieldSchema = @findFieldSchema(maskEntry, fieldnameDatamodel)
        if fieldSchema
          return fieldSchema
      if fieldSchema
        return fieldSchema
    return fieldSchema

  getTabs: (tabs) ->
    that = @

    # get fields from baseconfig
    baseConfig = ez5.session.getBaseConfig("plugin", "default-values-from-pool")
    config = baseConfig['DefaultValuesFromPool']['default_value_field_definitor'] || baseConfig['DefaultValuesFromPool']
    if config
      if typeof config is 'string'
        config = JSON.parse config
      @config = config

    if !config or !config.data_table
      return

    fields = []

    # build fields (only input, dante are allowed)
    for field in config.data_table

      if field?.fieldname && field?.label && field?.objecttype && field?.fieldtype

        ##########################################################################################
        # input text_online
        ##########################################################################################
        if field.fieldtype == 'input'
          newField =
            type: CUI.Input
            textarea: false
            name: field.fieldname
            form:
              label: field.label
              hint: 'Objecttype: ' + field.objecttype + ' - Fieldname: ' + field.fieldname
          fields.push newField

        ##########################################################################################
        # DANTE-field
        ##########################################################################################
        if field.fieldtype == 'dante'
          newField =
            type: CUI.DataFieldProxy
            name: 'dante'
            element: ((field) ->
              return (datafield) ->
                data = datafield.getData()

                #dataFieldNode = CUI.dom.matchSelector(datafield.DOM, ".cui-data-field")
                dataFieldNode = datafield.getDataFields()[0]
                dante = new CustomDataTypeDANTE
                opts = {
                  data: data
                  name: datafield.getName()
                  callfrompoolmanager: true
                  initialcallfrompoolmanager: true
                  editorstyle: field.dantemode
                  voc: field.dantevoc
                  datafieldproxy: dataFieldNode
                }
                # clone opts, because of async
                optsClone = CUI.util.copyObject(opts)
                value = dante.renderEditorInput(data, {}, optsClone)
                return value
            )(JSON.parse(JSON.stringify(field)))

            name: field.fieldname
            form:
              label: field.label
              hint: 'Objecttype: ' + field.objecttype + ' - Fieldname: ' + field.fieldname
          fields.push newField

        ##########################################################################################
        # Objecttype-Link
        ##########################################################################################
        if ((field.fieldtype.startsWith ('record')) && (field?.fieldname_datamodel != '') and field.fieldname_datamodel == 'defaultvalues_linkedobject.objecttypetest') 
          objecttype = field?.objecttype
          linkedObjecttype = field?.fieldtype.split('|||')[1]
          fieldnameDatamodel = field.fieldname_datamodel
   
          # get schemaTable
          schemaTable = ez5.schema.CURRENT._table_by_name?[objecttype]
          if !schemaTable
            console.log "schemaTable not found. field: ", field
            return
          
          _preferred_mask = schemaTable._preferred_mask
          maskFields = schemaTable._preferred_mask.fields

          # loop through all masks and find fieldSchema
          fieldSchema = that.findFieldSchema(maskFields, fieldnameDatamodel)
          if !fieldSchema
            console.log "fieldSchema not found. field: ", field
            return

          availableMasks = ez5.mask.CURRENT._masks_by_table_id[schemaTable.table_id]
          # loop through all masks and find the one with the name __all_fields
          for maskEntry in availableMasks
            if maskEntry.name.endsWith '__all_fields'
              allFieldsMask = maskEntry
              break
          if !allFieldsMask
            allFieldsMask = availableMasks[0]

          console.warn "fieldSchema: ", fieldSchema
          console.warn "allFieldsMask: ", allFieldsMask
                  
          maskForLinkedObject = new Mask("CURRENT", allFieldsMask.mask_id)

          newField =     
              type: CUI.DataFieldProxy
              name: 'linkedObject_' + field.fieldname + '_' + objecttype
              element: (df) =>
                  #console.log "df: ", df
                  #data = df.getData()
                  #that.opts.pool.data.pool.custom_data = data
                  linkedObjectField = new LinkedObject(maskForLinkedObject, fieldSchema)
                  linkedObjectField = linkedObjectField.renderEditorInput(that.opts.pool.data.pool.custom_data, {}, {})
                  console.log "linkedObjectField: ", linkedObjectField  
                  return linkedObjectField
              form:
               label: field.label
               hint: 'Objecttype: ' + field.objecttype + ' - Fieldname: ' + field.fieldname
          fields.push newField

    tabs.push
      name: $$('defaultvaluesfrompool.pool.manager.default.values.tab.headline')
      text: $$('defaultvaluesfrompool.pool.manager.default.values.tab.headline')
      content: =>
        form = new CUI.Form
          data: @_pool.data.pool
          name: "custom_data"
          fields: fields
        return form.start()
    return tabs

  getSaveData: (save_data) ->
    that = @
    for customFieldKey, customField of that._pool.data.pool.custom_data
      if customField
        save_data.pool.custom_data[customFieldKey] = CUI.util.copyObject(customField,true)
    # delete values from pool custom-data, if not given here / in baseconfig
    for customDataKey, customDataValue of save_data.pool.custom_data
      isValid = false
      for field in that.config.data_table
        if field.fieldname == customDataKey
          isValid = true
      if ! isValid
        delete save_data.pool.custom_data[customDataKey]
    return save_data


Pool.plugins.registerPlugin(ez5.PoolManagerDefaultValues)