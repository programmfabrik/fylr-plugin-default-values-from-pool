class ez5.ShowPoolDefaultValuesInMask extends CustomMaskSplitter

  _getAllowedFieldTypes: ->
    allowedTypes = [
      'text_oneline',
      'custom:base.custom-data-type-dante.dante',
      'custom:extension.custom-data-type-dante.dante'
    ]
    return allowedTypes

  isSimpleSplit: ->
    return false

  renderAsField: ->
    return true

  renderField: (opts) ->
    that = @

    # get objecttype-name
    objecttype = opts.top_level_data._objecttype

    # Gruppeneditor? --> den Splitter nicht nutzen
    if opts.bulk && opts.mode == "editor-bulk"
      return CUI.dom.append(@renderInnerFields(opts))

    # Keine PoolID vergeben? -->  den Splitter nicht nutzen
    poolID = opts.top_level_data[objecttype]?._pool?.pool?._id
    if ! poolID
      return CUI.dom.append(@renderInnerFields(opts))

    # poolid natürlich entsprechend oben auslesen und unten einsetzen
    poolInfo = ez5.pools.findPoolById(poolID)

    customDataFromPool = poolInfo.data.pool.custom_data

    # get inner fields
    innerFields = @renderInnerFields(opts)

    defaultValueFromPool = ''
    for key, entry of customDataFromPool
      if key == @getDataOptions().defaultInfoLinkFromPool
        defaultValueFromPool = entry
        if typeof defaultValueFromPool == 'object'
          defaultValueFromPool = defaultValueFromPool?.conceptName

    fieldsRendererPlain = @__customFieldsRenderer.fields[0]
    fields = fieldsRendererPlain.getFields() or []

    #####################################################################################
    # EDITOR-Mode
    #####################################################################################

    if opts.mode == "editor" || opts.mode == "editor-bulk"
      if fields
        field = fields[0]

        innerFieldsCollection = @renderInnerFields(opts)

        selectedElement = innerFieldsCollection.item(0)

        fieldnameblock = selectedElement.querySelector('.ez5-field-block-header')

        copiedFieldnameBlock = fieldnameblock.cloneNode(true)

        selectedElement.querySelector('.ez5-field-block-header').style.display = 'none'

        # in input einen placeholder setzen
        testForInput = selectedElement.querySelector('.cui-input input')
        if testForInput
          testForInput.placeholder = $$('fylr-plugin-default-values-from-pool-default-value.splitter.placeholder')

        # wenn Feld einen Wert hat, dann Button anzeigen, ansonsten verstecken
        # wenn Feld einen Wert hat, dann Standardwert nicht anzeigen
        buttonClassHidden = ''
        labelClassHidden = 'show'
        if opts.data[field.ColumnSchema.name]
          # if field has value, show x-button and hide defaultvalue from pool
          buttonClassHidden = 'show'
          labelClassHidden = 'hidden'

          # if field has no value, show default value and hide button
          if opts.data[field.ColumnSchema.name] == null || (typeof opts.data[field.ColumnSchema.name] == 'object' && ! opts.data[field.ColumnSchema.name]?.conceptURI) || (opts.data[field.ColumnSchema.name] == '')
            labelClassHidden = 'show'
            buttonClassHidden = 'hidden'

        # x-button for splitter-layout
        xButton = new CUI.Button
          class: 'fylr-plugin-default-values-from-pool-x-button ' + buttonClassHidden
          icon_left: new CUI.Icon(class: "fa-times")
          tooltip:
            text: $$('fylr-plugin-default-values-from-pool-default-value-remove-custom-value')
          onClick: (evt,button) =>
            opts.data[field.ColumnSchema.name] = null
            # clear value of field
            dataField = CUI.dom.matchSelector(selectedElement, ".cui-data-field")[0]
            domData = CUI.dom.data(dataField, "element")
            # if dante
            type = domData.__cls
            if type == 'Form'
              domData.unsetData()
              domData.opts.data = {}
              domData._data = {}
              opts.data[field.ColumnSchema.name] = {}

              CUI.Events.trigger
                type: 'custom-deleteDataFromPlugin'
                node: domData
                bubble: true
              CUI.Events.trigger
                type: 'editor-changed'
                node: domData
                bubble: true

            # if text_oneline
            if type == 'Input'
              domData.setValue('')
              domData.displayValue()

              CUI.Events.trigger
                type: 'data-changed'
                node: dataField
                bubble: true
              CUI.Events.trigger
                type: 'editor-changed'
                node: dataField
                bubble: true

        # Element, welches den Standardwert aus dem Pool anzeigt
        defaultLabelElement = new CUI.Label
                                     text: defaultValueFromPool + ' (' + $$('fylr-plugin-default-values-from-pool-default-value.splitter.hint') + ')'
                                     class: 'fylr-plugin-default-values-from-pool-default-value ' + labelClassHidden

        # create layout for splitter
        verticalLayout = new CUI.VerticalLayout
          class: "fylr-plugin-default-values-from-pool editormode"
          maximize: true
          top:
            class: 'fylr-plugin-default-values-from-pool-header'
            content: copiedFieldnameBlock
          center:
            content: defaultLabelElement
          bottom:
            content:
                      new CUI.HorizontalLayout
                        class:  "fylr-plugin-default-values-from-pool-input-layout"
                        left:
                          content: ''
                        center:
                          content: innerFieldsCollection
                        right:
                          content: xButton

        # listen for changes in field
        CUI.Events.listen
          type: ["data-changed"]
          node: selectedElement
          call: (ev, info) =>
            # if value is not empty, hide default value and show button
            hasValue = false
            if opts.data[field.ColumnSchema.name]
              hasValue = true
              if ! opts.data[field.ColumnSchema.name]?.conceptURI || opts.data[field.ColumnSchema.name]?.conceptURI == '' || opts.data[field.ColumnSchema.name]?.conceptURI == null
                opts.data[field.ColumnSchema.name] = {}
                hasValue = false

            if hasValue
              # show button
              CUI.dom.addClass(xButton, 'show')
              # show default value
              CUI.dom.removeClass(defaultLabelElement, 'show')
            else
              # hide button
              CUI.dom.removeClass(xButton, 'show')
              # hide default value
              CUI.dom.addClass(defaultLabelElement, 'show')

            CUI.Events.trigger
              type: 'editor-changed'
              node: selectedElement
              bubble: true

        CUI.Events.registerEvent
          type: "custom-deleteDataFromPlugin"
          bubble: false

        return CUI.dom.append(verticalLayout)

    #####################################################################################
    # DETAIL-Mode
    #####################################################################################

    if opts.mode == "detail"
      if fields
        field = fields[0]

        fieldType = field.ColumnSchema.type
        if ! fieldType in that._getAllowedFieldTypes()
          return

        fieldLabelL10n = field.ColumnSchema.name_localized
        # get frontendLanguage
        frontendLanguage = ez5.loca.getLanguage()
        # get label in frontendLanguage
        if fieldLabelL10n[frontendLanguage]
          fieldLabel = fieldLabelL10n[frontendLanguage]
        else
          fieldLabel = Object.keys(fieldLabelL10n)[0]
          firstKey = Object.keys(fieldLabelL10n)[0]
          fieldLabel = fieldLabelL10n[firstKey]

        fieldValue = opts.data[field.ColumnSchema.name]

        isDefaultValue = false;
        if typeof fieldValue == 'object'
          if fieldValue?.conceptName
            fieldValue = fieldValue.conceptName
          else
            if defaultValueFromPool?.conceptName
              fieldValue = defaultValueFromPool.conceptName
              isDefaultValue = true
        else if typeof fieldValue == 'string' || typeof fieldValue == 'undefined'
          if fieldValue == '' || fieldValue == undefined
            if defaultValueFromPool?.conceptName
              fieldValue = defaultValueFromPool.conceptName
            else
              fieldValue = defaultValueFromPool
            isDefaultValue = true

        cuiLabelLabel = fieldValue
        if isDefaultValue
          cuiLabelLabel = cuiLabelLabel + ' (' + $$('fylr-plugin-default-values-from-pool-default-value.splitter.hint') + ')'

        verticalLayout = new CUI.VerticalLayout
          class: "fylr-plugin-default-values-from-pool detailmode"
          maximize: true
          top:
            class: 'fylr-plugin-default-values-from-pool-header'
            content: fieldLabel
          center:
            content: new CUI.Label
                       text: cuiLabelLabel
                       class: 'fylr-plugin-default-values-from-pool-default-value'

        return CUI.dom.append(verticalLayout)

    return

    #return innerFields

  getOptions: ->
    # get available fields from baseconfig and choose only those, who match the objecttype
    baseConfig = ez5.session.getBaseConfig("plugin", "default-values-from-pool")
    config = baseConfig['DefaultValuesFromPool']['default_value_field_definitor'] || baseConfig['DefaultValuesFromPool']
    if config
      config = JSON.parse config
      @config = config

    fieldOptions = []
    fieldsFound = false
    if config?.data_table
      for field in config.data_table
        if @.opts?.maskEditor?.current_mask?.table?.name
          if @.opts.maskEditor.current_mask.table.name == field.objecttype
            newOption =
              value : field.fieldname
            fieldsFound = true
            fieldOptions.push newOption

    # show hint, if record was not saved yet
    if ! fieldsFound
      fieldOptions = []
      emptyOption =
          value : null
          text : $$('fylr-plugin-default-values-from-pool.options.empty_save')

      fieldOptions.push emptyOption

    maskOptions = [
      form:
        label: $$('show.pool.info.in.mask.nameofdefaultInfoLinkFromPool')
      type: CUI.Select
      name: "defaultInfoLinkFromPool"
      options: fieldOptions
    ]

    maskOptions

  trashable: ->
    true

  isEnabledForNested: ->
    return true

CUI.ready =>
  MaskSplitter.plugins.registerPlugin(ez5.ShowPoolDefaultValuesInMask)
