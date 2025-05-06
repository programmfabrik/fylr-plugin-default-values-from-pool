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

    CUI.Events.registerEvent
      type: "custom-deleteDataFromPlugin"
      bubble: false

    # get objecttype-name
    objecttype = opts.top_level_data?._objecttype

    # is splitter in summary of popover-mode?
    isInSummary = false
    if opts?.__is_in_nested_summary
      isInSummary = opts.__is_in_nested_summary

    # poolid
    poolID = false
    if opts?.top_level_data
      if opts?.top_level_data[objecttype]
        if opts?.top_level_data[objecttype]?._pool?.pool?._id
          poolID = opts?.top_level_data[objecttype]?._pool?.pool?._id

    # Gruppeneditor / Expertensuche / nested summary / keine poolID --> den Splitter nicht nutzen
    if (opts.bulk && opts.mode == "editor-bulk") || opts.mode == "expert" || isInSummary || !poolID
      div = CUI.dom.element("div", class: "fylr-plugin-default-values-from-pool" )
      return CUI.dom.append(div, @renderInnerFields(opts))

    # poolid natürlich entsprechend oben auslesen und unten einsetzen
    poolInfo = ez5.pools.findPoolById(poolID)
    # poolinfo da?
    if !poolInfo
      div = CUI.dom.element("div", class: "fylr-plugin-default-values-from-pool" )
      return CUI.dom.append(div, @renderInnerFields(opts))

    customDataFromPool = poolInfo.data.pool.custom_data

    # get inner fields
    innerFields = @renderInnerFields(opts)

    defaultValueFromPool = ''
    for key, entry of customDataFromPool
      if key == @getDataOptions().defaultInfoLinkFromPool
        defaultValueFromPool = entry
        if typeof defaultValueFromPool == 'object'
          defaultValueFromPool = defaultValueFromPool?.conceptName
          if !defaultValueFromPool
            if entry?._standard?[1].text
              # try in active frontendlanguage
              defaultValueFromPool = entry?._standard[1]?.text[ez5.loca.getLanguage()]
              # else get first language
              if !defaultValueFromPool
                defaultValueFromPool = entry?._standard[1]?.text[Object.keys(entry._standard[1].text)[0]]

    fieldsRendererPlain = @__customFieldsRenderer.fields[0]
    fields = fieldsRendererPlain.getFields() or []

    #####################################################################################
    # EDITOR-Mode
    #####################################################################################

    # is the splitter in an nested summary?
    isInSummary = false
    if opts?.__is_in_nested_summary
      isInSummary = opts.__is_in_nested_summary

    if (opts.mode == "editor" || opts.mode == "editor-bulk" || opts.mode == "editor-template") && (!isInSummary)
      if fields
        field = fields[0]

        innerFieldsCollection = @renderInnerFields(opts)

        if innerFieldsCollection.length == 0
          return

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
          if opts.data[field.ColumnSchema.name] == {} || opts.data[field.ColumnSchema.name] == null || (typeof opts.data[field.ColumnSchema.name] == 'object' && ! opts.data[field.ColumnSchema.name]?.conceptURI) || (opts.data[field.ColumnSchema.name] == '')
            labelClassHidden = 'show'
            buttonClassHidden = 'hidden'     

          # linkedobjecttype
          if opts.data[field.ColumnSchema.name]?._standard
            buttonClassHidden = 'show'
            labelClassHidden = 'hidden'

        # if dante-popover or dante-treeview or objecttype => Don't use the xbutton
        noxbuttonuseclass = ''
        # check if it is popover / treeview
        checkForDropdown = CUI.dom.matchSelector(selectedElement, ".customPluginEditorLayout.dropdown")[0]
        checkForInput = CUI.dom.matchSelector(selectedElement, ".cui-input.cui-data-field")[0]
        checkForDANTEInput = CUI.dom.matchSelector(selectedElement, ".pluginDirectSelectEditInput")[0]
        checkForLinkedObjecttype = CUI.dom.matchSelector(selectedElement, ".ez-linked-object-edit-object")[0]

        if ! checkForDropdown && ! checkForInput
          noxbuttonuseclass = 'noxbutton'
        if checkForDANTEInput
          noxbuttonuseclass = 'noxbutton'

        # x-button for splitter-layout
        xButton = new CUI.Button
          class: 'fylr-plugin-default-values-from-pool-x-button ' + buttonClassHidden + noxbuttonuseclass
          icon_left: new CUI.Icon(class: "fa-times")
          tooltip:
            text: $$('fylr-plugin-default-values-from-pool-default-value-remove-custom-value')
          onClick: (evt,button) =>
            # clear value of field
            dataField = CUI.dom.matchSelector(selectedElement, ".cui-data-field")[0]
            domData = CUI.dom.data(dataField, "element")

            # get type
            type = domData.__cls

            # if dante or objecttype
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
              CUI.Events.trigger
                type: 'data-changed'
                node: selectedElement
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


        ####################################################################
        # listen for changes in customdatafields
        # reset customdataform via another plugin (f.e. fylr-editor-field-visibility)
        ####################################################################
        customDataTypeNode = CUI.dom.matchSelector(selectedElement, ".customPluginEditorLayout")

        # if dante-dropdown-mode
        if customDataTypeNode.length == 0
          customDataTypeNode = CUI.dom.matchSelector(selectedElement, ".dante_InlineSelect")

        if customDataTypeNode
          CUI.Events.listen
            type: ["custom-deleteDataFromPlugin"]
            node: customDataTypeNode[0]
            call: (ev, info) =>
                # hide button
                CUI.dom.removeClass(xButton, 'show')
                # hide default value
                CUI.dom.addClass(defaultLabelElement, 'show')

        # listen for changes in field and show or hide buttons
        if selectedElement[0]
          selectedNode = selectedElement[0]
        else 
          selectedNode = selectedElement

        # dante and input
        CUI.Events.listen
          type: ["data-changed"]
          node: selectedNode
          call: (ev, info) =>
            # if value is not empty, hide default value and show button
            hasValue = false
            if opts.data[field.ColumnSchema.name]
              hasValue = true
              if opts.data[field.ColumnSchema.name] == null || opts.data[field.ColumnSchema.name] == {}
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

        # linkedobjecttype
        CUI.Events.listen
          type: ["editor-changed"]
          node: selectedNode
          call: (ev, info) =>
            # if value is not empty, hide default value and show button
            hasValue = false
            if opts.data[field.ColumnSchema.name]
              hasValue = true
              if opts.data[field.ColumnSchema.name] == null || opts.data[field.ColumnSchema.name] == {}
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


        div = CUI.dom.element("div", class: "fylr-plugin-default-values-from-pool" )
        return CUI.dom.append(div, verticalLayout)
        

    #####################################################################################
    # DETAIL-Mode
    #####################################################################################

    if opts.mode == "detail" || isInSummary == true
      if fields
        field = fields[0]

        if !field
          return

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
          else if defaultValueFromPool?.conceptName
              fieldValue = defaultValueFromPool.conceptName
              isDefaultValue = true
          else if fieldValue?._standard
              fieldValue = fieldValue?._standard[1]?.text[frontendLanguage]
              isDefaultValue = false
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

        unless typeof cuiLabelLabel is 'string'
            cuiLabelLabel = '(' + $$('fylr-plugin-default-values-from-pool-default-value.splitter.hint') + ')'
            
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

        div = CUI.dom.element("div", class: "fylr-plugin-default-values-from-pool" )
        return CUI.dom.append(div, verticalLayout)
    return

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
          value : {}
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
