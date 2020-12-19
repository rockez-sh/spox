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
  FormIcon
} from 'evergreen-ui'
import JSForm from "../lib/rjs_form";
import { useState, useEffect } from 'react';
import { humanizeString, formState, raiseError, toasterError} from '../Utils';

function getSchema(name, cb) {
   fetch('http://localhost:5001/api/sch/' + name)
   .then(resp => resp.ok ? resp.json() : raiseError(resp))
   .then(json => cb(json.data))
   .catch(toasterError)
}

function SchemaForm({schemaName}) {
  const [state, setState] = useState({
    schema: {}
  })
  useEffect(() => {
    function setSchema(schemaResp) {
      setState({schema: JSON.parse(schemaResp.value)})
    }
    if(schemaName != null)
      getSchema(schemaName, setSchema);
    return function cleanUp(){
      setState({schema: {}})
    }
  }, [schemaName])

  if(schemaName == null){
    return <Pane align="center" paddingTop={100}>
      <FormIcon size={80} color="muted" />
      <Heading size={700} marginTop={30} color="muted">Schema Form</Heading>
    </Pane>
  }else{
    return <JSForm schema={state.schema} />
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
          />
          <TextInputField
            label="Namespace"
            placeholder="namespace for your config"
            required={true}
            width="35%"
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
                  .map(value => ({ label: humanizeString(value), value: value }))
              }
              selected={state.form_data.schema}
              onSelect={stateUpdater('schema', (e) => e.value)}
              filterPlaceholder={"Choose a schema"}
              filterIcon={DocumentIcon}
              onFilterChange={fetchSchema}
            >
              <Button>{ state.form_data.schema ? humanizeString(state.form_data.schema) : 'Select Schema...'}</Button>
            </SelectMenu>
          </Pane>
        </Pane>
        <SchemaForm schemaName={state.form_data.schema} />
      </Pane>
    </Pane>
  )
}