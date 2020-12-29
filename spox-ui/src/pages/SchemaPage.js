import {
  Pane,
  Heading,
  DocumentIcon,
  TextInputField,
  TextareaField,
  Button,
  SavedIcon,
  SmallCrossIcon,
  toaster,
} from "evergreen-ui";
import JSONInput from "react-json-editor-ajrm";
import locale from "react-json-editor-ajrm/locale/en";
import { Link, useParams } from "react-router-dom";
import NOTFOUND from "./NOT_FOUND";
import { formState, apiCall } from "../Utils";

import { useState, useEffect } from "react";
import ActionPane from "../lib/ActionPane";
function raiseError(status) {
  throw new Error(status);
}

export default function SchemaPage() {
  const [state, setState] = useState({
    saving: false,
    saved: false,
    loaded: false,
    notFound: false,
    form_data: { name: null, desc: null, value: "{}" },
  });
  const stateUpdater = formState(state, setState);
  const { name: schemaName } = useParams();

  useEffect(() => {
    if (!schemaName) return;
    if (state.loaded) return;

    apiCall("/api/sch/" + schemaName).then(({ status, json }) => {
      if (status === 200)
        setState({ ...state, form_data: json.data, loaded: true });
      else if (status === 404)
        setState({ ...state, notFound: true, loaded: true });
    });
  }, [schemaName, state.loaded]);

  function submit() {
    setState({ ...state, saving: true });
    apiCall("/api/sch", {
      method: "POST",
      body: JSON.stringify({ sch: state.form_data }),
    }).then(({ status, json }) => {
      if (status == 200) {
        toaster.success("Schema saved 🎉");
        setState({ ...state, saving: false, loaded: true });
      }
    });
  }

  if (state.notFound) return <NOTFOUND />;

  return (
    <Pane>
      <Pane paddingBottom={10} borderBottom="muted" marginBottom={20}>
        <Heading size={700}>
          <DocumentIcon /> Schema
        </Heading>
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
            onChange={stateUpdater("name")}
          />
        </Pane>
        <TextareaField
          label="Description"
          value={state.form_data.desc}
          placeholder="A brief words what this config are for"
          onChange={stateUpdater("desc")}
        />
      </Pane>
      <Pane>
        <Pane elevation={3} padding={10}>
          <JSONInput
            id="a_unique_id"
            placeholder={JSON.parse(state.form_data.value)}
            locale={locale}
            height="550px"
            width="100%"
            theme="light_mitsuketa_tribute"
            style={{ body: { fontSize: "16px", backgroundColor: "#ffffff" } }}
            confirmGood={false}
            onBlur={(v) => {
              stateUpdater("value")({ target: { value: v.json } });
            }}
          />
        </Pane>
      </Pane>
      <ActionPane saving={state.saving} onSubmit={submit} />
    </Pane>
  );
}
