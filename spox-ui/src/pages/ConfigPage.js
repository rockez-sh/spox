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
import { humanizeString, formState, raiseError, toasterError} from '../Utils';
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
    schema: {}
  })
  // console.log(props)
  const {schemaName, schemaObject} = props
  useEffect(() => {
    function setSchema(schemaJson) {
      if(schemaJson.type != "object")
        schemaJson = {"type" : "object", "properties" : { "value" : schemaJson}};
      setState({schema: schemaJson })
    }
    if(schemaName != null && schemaObject == null )
      getSchema(schemaName,(x) => setSchema(x.value));
    else if(schemaObject != null)
      setSchema(schemaObject)

    return function cleanUp(){
      setState({schema: {}})
    }
  }, [schemaName, schemaObject])

  if(schemaName == null){
    return <Pane align="center" paddingTop={100}>
      <FormIcon size={80} color="muted" />
      <Heading size={700} marginTop={30} color="muted">Schema Form</Heading>
    </Pane>
  }else{
    return <JSForm schema={state.schema} {...props} />
  }
}

export default function ConfigPage (argument) {
  const [state, xsetState] = useState({
    saving: false,
    loaded: false,
    notFound: false,
    schema_value: {},
    schema_list: [],
    schema: null,
    form_data: { name: null, schema: null, namespace: null, value: null },
    schema_form_data: {}
  })
  function setState(newState) {
    console.log("setState:before", state)
    console.log("setState:new", newState)

    if(newState.schema_value && newState.schema_value.enabled)
      debugger;
    let r = xsetState(newState)
    console.log("setState:after", state)
    return r
  }
  const stateUpdater = formState(state, setState)
  const {name: configName, namespace: namespace} = useParams()

  function getConfig(cb) {
     fetch('http://localhost:5001/api/cog/' + namespace + '/' + configName)
     .then(resp => resp.ok ? resp.json() : raiseError(resp))
     .then(json => cb(json.data))
     .catch(toasterError)
  }
  function valueToFormData(val) {
    if(!state.loaded)
      return {};

    if(state.schema.type == "array"){
      return {"value" : JSON.parse(val)}
    }else if(state.schema.type == "string"){
      return {"value": Number(val)}
    }else if( ["integer", "number"].indexOf(state.schema.type) >= 0 ){
      return {"value": Number(val)}
    }else{
      return JSON.parse(val)
    }

  }
  function formDataToValue(formData) {
    if(!state.loaded)
      return {};

    if(state.schema.type == "array"){
      return JSON.stringify(formData.value)
    }else if(state.schema.type == "string"){
      return formData.value
    }else if( ["integer", "number"].indexOf(state.schema.type) >= 0 ){
      return formData.value
    }else{
      return JSON.stringify(formData)
    }

  }
  function saveConfig() {
    let form_data = {...state.form_data, value: formDataToValue(state.schema_value) }
    return fetch('http://localhost:5001/api/cog', {
      method: 'POST', // or 'PUT'
      headers: {'Content-Type': 'application/json', },
      body: JSON.stringify({cog: form_data}),
    })
    .then(response => {
      toaster.success("Schema saved 🎉")
      setState({...state, saving: false, loaded: true})
      response.json()
    })
    .catch((error) => {
      toaster.danger("Sorry, there is issue connecting to API")
      setState({...state, saving: false})
    });
  }

  useEffect(() => {
    if(configName != null && namespace != null)
      getConfig((data) => {
        getSchema(data.schema, (schema) => {
          let schemaJson = JSON.parse(schema.value)
          setState({...state,
            schema: schemaJson,
            schema_value: valueToFormData(data.value),
            form_data: data,
            loaded: true})
        })
      });
    return function cleanUp(){
      setState({...state, form_data: {}, loaded: false, schema_value: {}, schema: {} })
    }
  }, [configName, namespace])

  function fetchSchema(currentValue) {
    if(currentValue.length < 3)
      return ;
    fetch('http://localhost:5001/api/search', {
      method: 'POST', // or 'PUT'
      headers: {'Content-Type': 'application/json', },
      body: JSON.stringify({scope: "schemas", keyword: currentValue}),
    })
    .then(resp => resp.ok ? resp.json() : raiseError(resp.status))
    .then(json =>  setState({...state , schema_list: json.data.schemas.map(x => x.name) }))
    .catch(error => {
      console.log(error.message)
      if(error.message === "404"){
        setState({...state, notFound: true, loaded: true})
      }else{
        toasterError(error)
      }
    })
  }

  function setFormData(formData) {
    setState({...state, schema_value: formData})
    saveConfig()
  }


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
          />
          <TextInputField
            label="Namespace"
            placeholder="namespace for your config"
            required={true}
            width="35%"
            value={state.form_data.namespace}
            disabled={state.loaded}
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
              onSelect={stateUpdater('schema', (e) => e.value)}
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
          schemaName={state.form_data.schema}
          schemaObject={state.schema}
          formData={ state.schema_value }
          onSubmit={(x) => setFormData(x.formData) }
          onError={(x) => console.log('onError', x)} />
      </Pane>
    </Pane>
  )
}