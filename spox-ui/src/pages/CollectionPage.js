import { Pane, Heading, PropertiesIcon, TextInputField, TextareaField, toaster, SearchInput, Spinner,
  Table,
  Text,
  Button,
  EditIcon,
  PlusIcon
} from "evergreen-ui";
import { useState, useEffect } from "react";
import {
  humanizeString,
  formState,
  raiseError,
  toasterError,
  apiCall,
  notEmpty,
  isEmpty,
} from "../Utils";
import ActionPane from "../lib/ActionPane";
import { Link, useParams } from "react-router-dom";
import { DELAY_SEARCH } from "./SearchPage";
var typingTimer;
function SearchResultRow({config, index}) {
  const {name} = config
  return (
    <Table.Row key={index} height={32}>
      <Table.TextCell flexBasis={560} flexShrink={0} flexGrow={0}>
        <Text size={500}>{name}</Text>
      </Table.TextCell>
      <Table.TextCell textAlign="right" padding={5}>
        <Button
          marginRight={16}
          appearance="minimal"
          iconBefore={PlusIcon}
          is={Link}
          to={config}
        >
          Add
        </Button>
      </Table.TextCell>
    </Table.Row>
  )
}
function LoadingSearch({searching}) {
  return (
      <Pane textAlign="center" align="center" >
      {searching? <Spinner align="center" /> : <Text>No Config Found</Text>}
      </Pane>
    )
}
function SearchForm({exclude}) {
  const [state, setState] = useState({
    typing: false,
    lastTyping: 0,
    searching: false,
    term: null,
    results: [],
  });
  const filterResult = function(target) {
    console.log('target', target, 'exclude', exclude)
    console.log('filter', exclude.find(x => x.name === target.name && x.namespace === target.namespace))
    return isEmpty(exclude.find(x => x.name === target.name && x.namespace === target.namespace))
  }
  const apiSearch = (value) => {
    if (isEmpty(value)) {
      return setState((s) => {
        return { ...s, results: [] };
      });
    }

    setState((st) => {
      return { ...st, searching: true };
    });
    apiCall("/api/search", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ keyword: value, scope: "configs" }),
    }).then(({ status, json }) => {
      if (status == 200) {
        setState((s) => {
          const filtered_result = json.data.configs.filter(filterResult)
          console.log(filtered_result)
          return { ...s, searching: false, results: filtered_result };
        });
      }
    });
  };
  function typeSearch(x) {
    let value = x.target.value;
    setState({ ...state, typing: true, lastTyping: Date.now(), term: value });
    clearTimeout(typingTimer);

    typingTimer = setTimeout(() => {
      let { lastTyping } = state;
      let delta = Date.now() - lastTyping;
      if (delta >= DELAY_SEARCH) {
        apiSearch(value)
      }
    }, DELAY_SEARCH);
  }
  return (
    <Pane position="relative">
      <SearchInput
        width="100%"
        height={36}
        placeholder="Start Search to add config"
        onChange={typeSearch}
        value={state.term}
      />
      <Pane position="absolute"
        display={ isEmpty(state.term) ? 'none' : 'inherited'}
        top={36}
        elevation={3}
        width="100%"
        backgroundColor="#fff"
        zIndex={100}
        padding={20}
      >
      { isEmpty(state.results) ? <LoadingSearch searching={state.searching} /> : state.results.map( config => SearchResultRow({config}) ) }
      </Pane>
    </Pane>)
}

export default function CollectionPage(argument) {
  const [state, setState] = useState({
    loaded: false,
    saving: false,
    searching: false,
    term: null,
    form_data: { name: null, desc: null, namespace: null, configs: [] },
  });
  const stateUpdater = formState(state, setState);
  const { name: collectionName, namespace: namespace } = useParams();
  useEffect(() => {
    if (isEmpty(collectionName)) return;
    if (state.loaded) return;

    apiCall("/api/col/" + namespace + "/" + collectionName).then(({ status, json }) => {
      if (status === 200)
        setState({ ...state, form_data: json.data, loaded: true });
      else if (status === 404)
        setState({ ...state, notFound: true, loaded: true });
    });
  }, [collectionName, namespace, state.loaded]);

  const filterResult = state.form_data.configs.map(x => {return {...x, namespace: namespace}})
  function submit() {
    setState({ ...state, saving: true });
    apiCall("/api/col", {
      method: "POST",
      body: JSON.stringify({ col: state.form_data }),
    }).then(({ status, json }) => {
      if (status == 200) {
        toaster.success("Collection saved 🎉");
        setState({ ...state, saving: false, loaded: true });
      }
    });
  }

  return (
    <Pane>
      <Pane paddingBottom={10} borderBottom="muted" marginBottom={20}>
        <Heading size={700}>
          <PropertiesIcon /> Collection
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
          onChange={stateUpdater("desc")}
          value={state.form_data.desc}
        />
        <Pane display="" display={ state.loaded ? 'inherited'  : 'none' }>
          <Heading marginBottom={20}>Configs</Heading>
          <SearchForm exclude={ filterResult } />
          <Pane marginTop={20}>
            {state.form_data.configs.map((item, index) => {
              const { name } = item;
              return (
                <Table.Row key={index} height={32}>
                  <Table.TextCell flexBasis={560} flexShrink={0} flexGrow={0}>
                    <Text size={500}>{name}</Text>
                  </Table.TextCell>
                  <Table.TextCell textAlign="right" padding={5}>
                    <Button
                      marginRight={16}
                      appearance="minimal"
                      iconBefore={EditIcon}
                      is={Link}
                      to={item}
                    >
                      edit
                    </Button>
                  </Table.TextCell>
                </Table.Row>
              );
            })}
          </Pane>
        </Pane>
        <ActionPane saving={state.saving} onSubmit={submit} />
      </Pane>
    </Pane>
  );
}
