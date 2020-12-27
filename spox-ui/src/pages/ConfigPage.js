import {
  Pane,
  Heading,
  WrenchIcon,
  TextInputField,
  TextareaField,
  Text,
  Combobox,
  TextInput,
  DocumentIcon,
  SelectMenu,
  Button,
  FormIcon,
  toaster
} from 'evergreen-ui'
import JSForm from "../lib/rjs_form";
import { useState, useEffect } from 'react';
import {
  humanizeString,
  formState,
  raiseError,
  toasterError,
  apiCall,
  notEmpty
} from '../Utils';

import {
  useParams
} from "react-router-dom";

function getSchema(name, cb) {
   fetch('http://localhost:5001/api/sch/' + name)
   .then(resp => resp.ok ? resp.json() : raiseError(resp))
   .then(json => cb(json.data))
   .catch(toasterError)
}

function SchemaForm(props) {
  const [state, setState] = useState({
    schema: {},
    loaded: false
  })
  const {schemaName, schemaValue, onSubmit, onChange} = props

  function formDataToValue(formData) {
    if(state.schema.type === "array"){
      return JSON.stringify(formData.value)
    }else if(state.schema.type === "string"){
      return formData.value
    }else if( ["integer", "number"].indexOf(state.schema.type) >= 0 ){
      return formData.value
    }else{
      return JSON.stringify(formData)
    }
  }

  function valueToFormData(value) {
    if(!state.loaded)
      return {};
    if(state.schema.type === "array"){
      return {value: JSON.parse(value)}
    }else if(state.schema.type === "string"){
      return {value: value}
    }else if( ["integer", "number"].indexOf(state.schema.type) >= 0 ){
      return {value: Number(value)}
    }else{
      return JSON.parse(value)
    }
  }

  function setSchema(schemaJson) {
    if(schemaJson.type !== "object")
      schemaJson = {"type" : "object", "properties" : { "value" : schemaJson}};
    setState({...state,schema: schemaJson, loaded: true })
  }

  useEffect(() => {
    if(notEmpty(schemaName)){
      apiCall('/api/sch/' + schemaName)
      .then(({status, json}) => {
        if(status == 200){
          let {data: {value}} = json
          setSchema(JSON.parse(value))
        }
      })
    }
    return function cleanUp(){
      setState({schema: {}, loaded: false})
    }
  }, [schemaName])


  if(schemaName === null){
    return <Pane align="center" paddingTop={100}>
      <FormIcon size={80} color="muted" />
      <Heading size={700} marginTop={30} color="muted">Schema Form</Heading>
    </Pane>
  }else{
    return <JSForm
    schema={state.schema}
    formData={ valueToFormData(schemaValue)}
    onSubmit={ (x) => onSubmit(formDataToValue(x.formData)) }
    onChange={ (x) => onChange(formDataToValue(x.formData)) }
    />
  }
}

export default function ConfigPage (argument) {
  const [state, setState] = useState({
    saving: false,
    loaded: false,
    notFound: false,
    schema_list: [],
    schema: null,
    form_data: { name: null, schema: null, namespace: null, value: null },
    schema_form_data: {}
  })

  const stateUpdater = formState(state, setState)
  const {name: configName, namespace} = useParams()

  function saveConfig(value) {
    return apiCall('/api/cog', {
      method: 'POST',
      headers: {'Content-Type': 'application/json' },
      body: JSON.stringify({cog: {...state.form_data, value}}),
    })
    .then( ({status, json}) => {
      if(status == 200){
        toaster.success("Schema saved 🎉")
        setState({...state, saving: false, loaded: true})
      }
    })
    .catch((error) => {
      toaster.danger("Sorry, there is issue connecting to API")
      setState({...state, saving: false})
    });
  }
  function fetchSchema(currentValue) {
      if(currentValue.length < 3)
        return ;
      apiCall("/api/search", {
        method: 'POST',
        headers: {'Content-Type': 'application/json' },
        body: JSON.stringify({scope: "schemas", keyword: currentValue}),
      })
      .then(({status, json}) => {
        if(status == 200){
          setState({...state,schema_list: json.data.schemas.map(x => x.name) })
        }
      })
  }

  useEffect(() => {
    if(configName !== undefined && namespace !== undefined){
      apiCall('/api/cog/' + namespace + '/' + configName)
      .then(({status, json})=> {
        let {data} = json
        if(status === 404){
          setState({...state, notFound: true})
          return Promise.resolve(undefined)
        }
        if(status === 200){
          setState({...state, loaded: true, form_data: data })
        }
      })
    }
    return function cleanUp(){
      setState({ form_data: {}, loaded: false})
    }
  }, [configName, namespace])

  return (
    <Pane>
      <Pane paddingBottom={10} borderBottom="muted" marginBottom={20}>
        <Heading size={700}><WrenchIcon/>  Config</Heading>
      </Pane>
      <Pane borderBottom="muted" marginBottom={20}>
        <Pane display="flex">
          <TextInputField
            label="Name"
            placeholder="Must be uniq per namespace, only alphanumeric & underscore are allowed"
            required={true}
            width="60%"
            marginRight={40}
            value={state.form_data.name}
            disabled={state.loaded}
            onChange={stateUpdater('name')}
          />
          <TextInputField
            label="Namespace"
            placeholder="namespace for your config"
            required={true}
            width="35%"
            value={state.form_data.namespace}
            disabled={state.loaded}
            onChange={stateUpdater('namespace')}
          />

        </Pane>
        <TextareaField
          label="Description"
          placeholder="A brief words what this config are for"
        />
      </Pane>
      <Pane>
        <Pane display="flex">
          <Text marginRight={40} size={500} lineHeight="32px">Schema</Text>
          <Pane>
            <SelectMenu
              title="Select name"
              options={
                state.schema_list
                  .map(value => ({ label: value, value: value }))
              }
              selected={state.form_data.schema}
              onSelect={ stateUpdater('schema', (e) => e.value) }
              filterPlaceholder={"Choose a schema"}
              filterIcon={DocumentIcon}
              onFilterChange={fetchSchema}
              closeOnSelect={true}
            >
              <Button>{ state.form_data.schema ? state.form_data.schema : 'Select Schema...'}</Button>
            </SelectMenu>
          </Pane>
        </Pane>
        <SchemaForm
          schemaName={ state.form_data.schema }
          schemaValue={ state.form_data.value }
          onSubmit={ saveConfig }
          onChange={ stateUpdater('value') }
          onError={(x) => console.log('onError', x)} />
      </Pane>
    </Pane>
  )
}