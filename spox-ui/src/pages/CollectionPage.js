import { Pane, Heading, PropertiesIcon, TextInputField, TextareaField, toaster, SearchInput, Spinner,
  Table,
  Text,
  Button,
  EditIcon,
  PlusIcon,
  CrossIcon,
  IconButton
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
import { Link, useParams, useHistory } from "react-router-dom";
import { DELAY_SEARCH } from "./SearchPage";
var typingTimer;
const itemFinder = function(target, matcher=true) {
  return function(x){
    let match = x.name === target.name && x.namespace === target.namespace
    return matcher ? match : !match
  }
}

function SearchResultRow({config, index, onItemClick}) {
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
          onClick={ () => onItemClick(config) }
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
function SearchForm({exclude, onItemClick}) {
  const [state, setState] = useState({
    typing: false,
    lastTyping: 0,
    searching: false,
    term: null,
    results: [],
  });
  const filterResult = function(target) {
    return isEmpty(exclude.find(itemFinder(target)))
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
          return { ...s, searching: false, results: json.data.configs };
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
  let filtered_result = state.results.filter(filterResult)
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
      { isEmpty(filtered_result) ? <LoadingSearch searching={state.searching} /> : filtered_result.map( (config, index) => SearchResultRow({config, onItemClick, index}) ) }
      </Pane>
    </Pane>)
}

export default function CollectionPage(argument) {
  const [state, setState] = useState({
    loaded: false,
    saving: false,
    searching: false,
    add_configs: [],
    remove_configs: [],
    term: null,
    form_data: { name: null, desc: null, namespace: null, configs: [] },
    original_form_data: {}
  });
  const stateUpdater = formState(state, setState);
  const { name: collectionName, namespace: namespace } = useParams();
  let history = useHistory()

  useEffect(() => {
    if (isEmpty(collectionName)) return;
    if (state.loaded) return;

    apiCall("/api/col/" + namespace + "/" + collectionName).then(({ status, json }) => {
      if (status === 200){
        setFormData(json.data, {loaded: true})
      }
      else if (status === 404)
        setState({ ...state, notFound: true, loaded: true });
    });
  }, [collectionName, namespace, state.loaded]);


  function addConfig(config) {
    const finder = itemFinder(config, true)
    const unFinder = itemFinder(config, false)
    const {form_data, original_form_data, remove_configs, add_configs} = state
    const {name, value, namespace} = config

    if(original_form_data.configs.find(finder)){
      setState({...state,
        remove_configs: remove_configs.filter(unFinder),
        form_data: {...form_data,
          configs: form_data.configs.concat([{name, value, namespace}]) }
      });
    }else{
      setState({...state,
        add_configs: add_configs.concat([{...config, is_new: true}])
      })
    }
  }

  function setFormData(form_data, extra){
    const {namespace} = form_data
    const configs = form_data.configs.map( x => {return {...x, namespace}} )
    const newFormData = {...form_data, configs}
    setState({ ...state, ...extra, form_data: newFormData, original_form_data: newFormData });
  }

  function removeConfig(config) {
    const finder = itemFinder(config, true)
    const unFinder = itemFinder(config, false)
    const {form_data, remove_configs, add_configs, original_form_data} = state
    const {name, value, namespace} = config

    if(original_form_data.configs.find(finder)){
      setState({...state,
        remove_configs: remove_configs.concat([config]),
        form_data: {...form_data,
          configs: form_data.configs.filter(unFinder)}
      });
    }else{
      setState({...state,
        add_configs: add_configs.filter(unFinder)
      })
    }
  }
  function collectionDetailChanged(){
    const {form_data, original_form_data} = state
    return form_data.desc != original_form_data.desc
  }

  function isConfigsModified(){
    const {remove_configs, add_configs} = state
    return notEmpty(remove_configs) || notEmpty(add_configs)
  }

  function submit() {
    const {add_configs, form_data} = state
    const {namespace, name, configs} = form_data
    if(collectionDetailChanged() || isConfigsModified())
      setState({ ...state, saving: true });

    if(collectionDetailChanged()) {
      apiCall("/api/col", {
        method: "POST",
        body: JSON.stringify({ col: state.form_data }),
      }).then(({ status, json }) => {
        if (status == 200) {
          toaster.success("Collection saved 🎉");
          setFormData(json, {loaded: true, saving: false})
        }
      });
    }

    if(isConfigsModified()) {
      apiCall(`/api/col/${namespace}/${name}/add`, {
        method: "POST",
        body: JSON.stringify({ configs: state.add_configs.map(x => x.name) }),
      }).then(({ status, json }) => {
        if (status == 200) {
          toaster.success("Configs updated 🎉");
          let new_add_configs = add_configs.map( ({name, namespace}) => {return {name , namespace}})
          setState({...state, saving: false, add_configs: [],
            form_data: json.data})
        }else{
          const {message} = json
          toaster.danger(`😓  failed to udpdate configs, message: ${message}`);
          setState({...state, saving: false })
        }
      });
    }
  }

  let filteredConfig = state.form_data.configs.map(x => {return {...x, namespace}})
  filteredConfig = filteredConfig.concat(state.add_configs)

  return (
    <Pane width={700}>
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
            hint={ !state.loaded ? undefined : `🔖 ${state.form_data.version}`  }
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
          onChange={ stateUpdater("desc") }
          value={state.form_data.desc}
        />
        <Pane display="" display={ state.loaded ? 'inherited'  : 'none' }>
          <Heading marginBottom={20}>Configs</Heading>
          <SearchForm exclude={ filteredConfig } onItemClick={addConfig} />
          <Pane marginTop={20}>
            {filteredConfig.map((item, index) => {
              const { name, is_new } = item;
              return (
                <Table.Row key={index} intent={ is_new ? 'success' : 'none'  } flexBasis={560} flexShrink={0} flexGrow={0} height={32}>
                  <Table.TextCell>
                    <Text size={500}>{name}</Text>
                  </Table.TextCell>
                  <Table.TextCell textAlign="right" padding={5}>
                    <Pane float="right"  display="flex" align="right" alignContent="flex-end">
                      <IconButton
                        appearance="minimal"
                        icon={EditIcon}
                        is={Link}
                        to={`/config/${namespace}/${name}`}
                      />
                      <IconButton
                        appearance="minimal"
                        icon={CrossIcon}
                        onClick={() => removeConfig(item)}
                      />
                    </Pane>
                  </Table.TextCell>
                </Table.Row>
              );
            })}
          </Pane>
        </Pane>
        <ActionPane saving={state.saving} history={history} onSubmit={submit} disabled={ !(collectionDetailChanged() || isConfigsModified()) } />
      </Pane>
    </Pane>
  );
}
