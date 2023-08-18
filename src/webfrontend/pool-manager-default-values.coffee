class ez5.PoolManagerDefaultValues extends ez5.PoolPlugin

  getTabs: (tabs) ->
    # get fields from baseconfig
    baseConfig = ez5.session.getBaseConfig("plugin", "default-values-from-pool")
    config = baseConfig['DefaultValuesFromPool']['default_value_field_definitor'] || baseConfig['DefaultValuesFromPool']
    if config
      config = JSON.parse config
      @config = config

    if !config or !config.data_table
      return

    fields = []

    # build fields (only input and dante are allowed)
    for field in config.data_table

      if field?.fieldname && field?.label && field?.objecttype && field?.fieldtype

        # input text_online
        if field.fieldtype == 'input'
          newField =
            type: CUI.Input
            textarea: false
            name: field.fieldname
            form:
              label: field.label
              hint: 'Objecttype: ' + field.objecttype + ' - Fieldname: ' + field.fieldname
          fields.push newField

        if field.fieldtype == 'dante'
          newField =
            type: CUI.DataFieldProxy
              # but save-button does not
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

    that = @
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
