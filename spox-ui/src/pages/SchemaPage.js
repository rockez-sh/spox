import {
  Pane,
  Heading,
  DocumentIcon,
  TextInputField,
  TextareaField,
  Button,
  SavedIcon,
  SmallCrossIcon
} from 'evergreen-ui';
import JSONInput from 'react-json-editor-ajrm';
import locale    from 'react-json-editor-ajrm/locale/en';
import {
  Link
} from "react-router-dom";

import { useState } from 'react';

export default function SchemaPage () {
  const [state, setState] = useState({
    saving: false,
    saved: false,
    persisted: false,
    form_data: { name: null, desc: null, value: '{}'
  }})

  function stateUpdater(attribute) {
    return function(e){
      let form_data = {...state.form_data, [attribute]: e.target.value}
      setState({...state, form_data})
    }
  }

  function submit() {
    setState({...state, saving: true})
    fetch('http://localhost:5001/api/sch', {
      method: 'POST', // or 'PUT'
      headers: {'Content-Type': 'application/json', },
      body: JSON.stringify({sch: state.form_data}),
    })
    .then(response => {
      response.json()
      setState({...state, saving: false})
    })
    .catch((error) => {
      console.error('Error:', error);
      setState({...state, saving: false})
    });
  }

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