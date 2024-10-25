class DefaultValueFieldDefinitorBaseConfig extends BaseConfigPlugin
  getFieldDefFromParm: (baseConfig, pname, def, parent_def) ->

    if def.plugin_type != "default-value-field-definitor"
      return

    # list of objecttypes for selection
    objecttypesOptions = []
    for ot in ez5.schema.CURRENT._objecttypes
      value = ot.name
      objectType = new Objecttype(new Table("CURRENT", ot.table_id))
      text = objectType.nameLocalized()
      text += " [#{objectType.name()}]"
      objecttypesOptions.push(
        text: text
        value: value
      )

    # generate form with datatable
    field =
      type: CUI.Form
      name: "default_value_field_definitor"
      fields: [
        type: CUI.DataTable
        name: "data_table"
        fields: [
          form:
            label: $$("defaultvaluefielddefinitor.data_table.objecttype")
          type: CUI.Select
          name: "objecttype"
          options: objecttypesOptions
        ,
          form:
            label: $$("defaultvaluefielddefinitor.data_table.label")
          type: CUI.Input
          name: "label"
        ,
          form:
            label: $$("defaultvaluefielddefinitor.data_table.fieldname")
          type: CUI.Input
          name: "fieldname"
        ,
          form:
            label: $$("defaultvaluefielddefinitor.data_table.fieldtype")
          type: CUI.Select
          text: $$("defaultvaluefielddefinitor.data_table.fieldtype.label")
          name: "fieldtype"
          options: [
              text: $$("defaultvaluefielddefinitor.data_table.fieldtype.input")
              value: 'input'
            ,
              text: $$("defaultvaluefielddefinitor.data_table.fieldtype.dante")
              value: 'dante'
          ]
        ,
          form:
            label: $$("defaultvaluefielddefinitor.data_table.dantevoc")
          type: CUI.Input
          name: "dantevoc"
        ,
          form:
            label: $$("defaultvaluefielddefinitor.data_table.dantemode")
          type: CUI.Select
          text: $$("defaultvaluefielddefinitor.data_table.dantemode.label")
          name: "dantemode"
          options: [
              text: $$("defaultvaluefielddefinitor.data_table.dantemode.empty")
              value: null
            ,
              text: $$("defaultvaluefielddefinitor.data_table.dantemode.dropdown")
              value: 'dropdown'
            ,
              text: $$("defaultvaluefielddefinitor.data_table.dantemode.popover")
              value: 'popover'
            ,
              text: $$("defaultvaluefielddefinitor.data_table.dantemode.treeview")
              value: 'popover_with_treeview'
          ]
        ]
      ]
    field

CUI.ready =>
  BaseConfig.registerPlugin(new DefaultValueFieldDefinitorBaseConfig())
