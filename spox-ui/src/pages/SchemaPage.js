import {
  Pane,
  Heading,
  DocumentIcon,
  TextInputField,
  TextareaField,
  Button,
  SavedIcon,
  SmallCrossIcon,
  toaster
} from 'evergreen-ui';
import JSONInput from 'react-json-editor-ajrm';
import locale    from 'react-json-editor-ajrm/locale/en';
import {
  Link,
  useParams
} from "react-router-dom";
import NOTFOUND from './NOT_FOUND';
import {formState} from '../Utils';

import { useState, useEffect } from 'react';

function raiseError(status){
  throw new Error(status)
}

export default function SchemaPage () {
  const [state, setState] = useState({
    saving: false,
    saved: false,
    loaded: false,
    notFound: false,
    form_data: { name: null, desc: null, value: '{}'
  }})
  const stateUpdater = formState(state, setState)
  const {name: schemaName} = useParams()

  useEffect(() => {
    if(!schemaName)
      return;
    if(state.loaded)
      return;

    fetch('http://localhost:5001/api/sch/'+schemaName)
    .then(resp => resp.ok ? resp.json() : raiseError(resp.status))
    .then(json =>  setState({...state , form_data: json.data, loaded: true }))
    .catch(error => {
      if(error.message === "404"){
        setState({...state, notFound: true, loaded: true})
      }
    })
  });


  function submit() {
    setState({...state, saving: true})
    fetch('http://localhost:5001/api/sch', {
      method: 'POST', // or 'PUT'
      headers: {'Content-Type': 'application/json', },
      body: JSON.stringify({sch: state.form_data}),
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

  if(state.notFound)
    return <NOTFOUND/>

  return (
    <Pane>
      <Pane paddingBottom={10} borderBottom="muted" marginBottom={20}>
        <Heading size={700}><DocumentIcon/>  Schema</Heading>
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
            onChange={ stateUpdater('name') }
          />
        </Pane>
        <TextareaField
          label="Description"
          value={state.form_data.desc}
          placeholder="A brief words what this config are for"
          onChange={ stateUpdater('desc') }
        />
      </Pane>
      <Pane>
        <Pane elevation={3} padding={10}>
          <JSONInput
            id          = 'a_unique_id'
            placeholder = { JSON.parse(state.form_data.value) }
            locale      = { locale }
            height      = '550px'
            width       = '100%'
            theme       = 'light_mitsuketa_tribute'
            style       = { {body: {fontSize: "16px", backgroundColor: "#ffffff" }} }
            confirmGood = {false}
            onBlur = { (v) => { stateUpdater('value')( {target: {value: v.json}} ) }}
          />
        </Pane>
      </Pane>
      <Pane padding={20} marginTop={20} textAlign="right" background="tint1">
        <Button is={Link} to="/" iconBefore={SmallCrossIcon} marginRight={15}>Cancel</Button>
        <Button appearance="primary" onClick={submit} iconBefore={state.saving ? null : SavedIcon} isLoading={state.saving}>
          {state.saving ? 'Saving ...' : 'Save'}
        </Button>
      </Pane>
    </Pane>
  )
}