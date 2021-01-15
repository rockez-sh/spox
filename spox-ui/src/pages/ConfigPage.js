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
  toaster,
} from "evergreen-ui";
import JSForm from "../lib/rjs_form";
import { useState, useEffect, useMemo } from "react";
import {
  humanizeString,
  formState,
  raiseError,
  toasterError,
  apiCall,
  notEmpty,
  isEmpty,
} from "../Utils";

import { useParams } from "react-router-dom";

import ActionPane from "../lib/ActionPane";

function getSchema(name, cb) {
  fetch("http://localhost:5001/api/sch/" + name)
    .then((resp) => (resp.ok ? resp.json() : raiseError(resp)))
    .then((json) => cb(json.data))
    .catch(toasterError);
}

function SchemaForm(props) {
  const [state, setState] = useState({
    schema: {},
    loaded: false,
  });
  const { schemaName, schemaValue, onSubmit, onChange, saving } = props;

  function formDataToValue(formData) {
    if (state.schema.type === "array") {
      return JSON.stringify(formData.value);
    } else if (state.schema.type === "string") {
      return isEmpty(formData.value) ? "" : formData.value;
    } else if (["integer", "number"].indexOf(state.schema.type) >= 0) {
      return isEmpty(formData.value) ? 0 : Number(formData.value);
    } else {
      return JSON.stringify(formData);
    }
  }

  const valueToFormData = useMemo(() => {
    if (!state.loaded) return {};
    if (state.schema.type === "array") {
      return { value: JSON.parse(schemaValue) };
    } else if (state.schema.type === "string") {
      return { value: isEmpty(schemaValue) ? "" : schemaValue };
    } else if (["integer", "number"].indexOf(state.schema.type) >= 0) {
      return { value: isEmpty(schemaValue) ? 0 : Number(schemaValue) };
    } else {
      return JSON.parse(schemaValue);
    }
  }, [schemaValue, state.loaded]);

  const schemaWrapper = useMemo(() => {
    if (state.schema.type !== "object")
      return { type: "object", properties: { value: state.schema } };
    else return state.schema;
  }, [schemaName, state.loaded]);

  useEffect(() => {
    if (notEmpty(schemaName)) {
      apiCall("/api/sch/" + schemaName).then(({ status, json }) => {
        if (status == 200) {
          const {
            data: { value },
          } = json;
          setState({ ...state, schema: JSON.parse(value), loaded: true });
        }
      });
    }
    return function cleanUp() {
      setState({ schema: {}, loaded: false });
    };
  }, [schemaName]);

  if (schemaName === null) {
    return (
      <Pane align="center" paddingTop={100}>
        <FormIcon size={80} color="muted" />
        <Heading size={700} marginTop={30} color="muted">
          Schema Form
        </Heading>
      </Pane>
    );
  } else {
    return (
      <JSForm
        schema={schemaWrapper}
        formData={valueToFormData}
        onSubmit={(x) => onSubmit(formDataToValue(x.formData))}
        onChange={(x) => onChange(formDataToValue(x.formData))}
      >
        <ActionPane saving={saving} />
      </JSForm>
    );
  }
}

export default function ConfigPage(argument) {
  const [state, setState] = useState({
    saving: false,
    loaded: false,
    notFound: false,
    schema_list: [],
    schema: null,
    form_data: { name: null, schema: null, namespace: null, value: null },
    schema_form_data: {},
  });

  const stateUpdater = formState(state, setState);
  const { name: configName, namespace } = useParams();

  function saveConfig(value) {
    setState({ ...state, saving: true });

    return apiCall("/api/cog", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ cog: { ...state.form_data, value } }),
    })
      .then(({ status, json }) => {
        if (status == 200) {
          toaster.success("Schema saved 🎉");
          setState({ ...state, saving: false, loaded: true });
        }
      })
      .catch((error) => {
        toaster.danger("Sorry, there is issue connecting to API");
        setState({ ...state, saving: false });
      });
  }
  function fetchSchema(currentValue) {
    if (currentValue.length < 3) return;
    apiCall("/api/search", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ scope: "schemas", keyword: currentValue }),
    }).then(({ status, json }) => {
      if (status == 200) {
        setState({
          ...state,
          schema_list: json.data.schemas.map((x) => x.name),
        });
      }
    });
  }

  useEffect(() => {
    if (configName !== undefined && namespace !== undefined) {
      apiCall("/api/cog/" + namespace + "/" + configName).then(
        ({ status, json }) => {
          let { data } = json;
          if (status === 404) {
            setState({ ...state, notFound: true });
            return Promise.resolve(undefined);
          }
          if (status === 200) {
            setState({ ...state, loaded: true, form_data: data });
          }
        }
      );
    }
    return function cleanUp() {
      setState({ ...state, form_data: {}, loaded: false });
    };
  }, [configName, namespace]);

  return (
    <Pane width={700}>
      <Pane paddingBottom={10} borderBottom="muted" marginBottom={20}>
        <Heading size={700}>
          <WrenchIcon /> Config
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
          <TextInputField
            label="Namespace"
            placeholder="namespace for your config"
            required={true}
            width="35%"
            value={state.form_data.namespace}
            disabled={state.loaded}
            onChange={stateUpdater("namespace")}
          />
        </Pane>
        <TextareaField
          label="Description"
          placeholder="A brief words what this config are for"
        />
      </Pane>
      <Pane>
        <Pane display="flex">
          <Text marginRight={40} size={500} lineHeight="32px">
            Schema
          </Text>
          <Pane>
            <SelectMenu display={state.loaded ? 'none' : 'inherited'}
              title="Select name"
              options={state.schema_list.map((value) => ({
                label: value,
                value: value,
              }))}
              selected={state.form_data.schema}
              onSelect={stateUpdater("schema", (e) => e.value)}
              filterPlaceholder={"Choose a schema"}
              filterIcon={DocumentIcon}
              onFilterChange={fetchSchema}
              closeOnSelect={true}
            >
              <Button display={state.loaded ? 'none' : 'inherited'}>
                {state.form_data.schema
                  ? state.form_data.schema
                  : "Select Schema..."}
              </Button>
            </SelectMenu>
            <TextInput
              display={!state.loaded ? 'none' : 'inherited'}
              placeholder="namespace for your config"
              value={state.form_data.schema}
              disabled={state.loaded} />
          </Pane>
        </Pane>
        <SchemaForm
          saving={state.saving}
          schemaName={state.form_data.schema}
          schemaValue={state.form_data.value}
          onSubmit={saveConfig}
          onChange={stateUpdater("value", (v) => v)}
          onError={(x) => console.log("onError", x)}
        />
      </Pane>
    </Pane>
  );
}
