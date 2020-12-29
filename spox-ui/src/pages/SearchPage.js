import MainMenu from "../MainMenu";
import {
  Pane,
  Heading,
  TextInput,
  Text,
  Table,
  Button,
  EditIcon,
  SearchInput,
  Spinner,
  CircleArrowRightIcon,
  BanCircleIcon,
} from "evergreen-ui";
import { useState, useEffect, useCallback, useMemo } from "react";
import { notEmpty, isEmpty, apiCall, useQuery } from "../Utils";
import { useHistory, Link } from "react-router-dom";

const DELAY_SEARCH = 500;
var typingTimer;
const EMPTY_OBJECT = {
  configs: [],
  collections: [],
  schemas: [],
};
function ResultGroup({ name, results, linkTo }) {
  if (isEmpty(results)) {
    return <div></div>;
  }
  return (
    <Pane marginBottom={20}>
      <Heading size={600}>{name}</Heading>
      <Pane paddingTop={20}>
        {results.map((item, index) => {
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
                  to={linkTo(item)}
                >
                  edit
                </Button>
              </Table.TextCell>
            </Table.Row>
          );
        })}
      </Pane>
    </Pane>
  );
}
export { DELAY_SEARCH };
export default function SearchPage() {
  let query = useQuery().get("q");
  let history = useHistory();

  const [state, setState] = useState({
    typing: false,
    lastTyping: 0,
    searching: false,
    term: null,
    results: EMPTY_OBJECT,
  });

  const apiSearch = (value) => {
    if (isEmpty(value)) {
      return setState((s) => {
        return { ...s, results: EMPTY_OBJECT };
      });
    }

    setState((st) => {
      return { ...st, searching: true };
    });
    apiCall("/api/search", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ keyword: value }),
    }).then(({ status, json }) => {
      if (status == 200) {
        setState((s) => {
          return { ...s, searching: false, results: json.data };
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
        history.push({
          pathname: "/search",
          search: "?" + new URLSearchParams({ q: value }).toString(),
        });
      }
    }, DELAY_SEARCH);
  }

  function emptyResult() {
    const { configs, schemas, collections } = state.results;
    if (
      isEmpty(configs) &&
      isEmpty(schemas) &&
      isEmpty(collections) &&
      notEmpty(query)
    )
      return true;
    return false;
  }
  useEffect(() => {
    apiSearch(query);
  }, [query]);

  return (
    <Pane marginTop={0}>
      <Pane display="flex">
        <Pane width="75%">
          <Heading size={700} marginBottom={0}>
            Spox
          </Heading>
        </Pane>
        <Pane width="25%" align="right">
          <MainMenu />
        </Pane>
      </Pane>
      <Pane position="relative">
        <SearchInput
          width="100%"
          height={48}
          placeholder="Start Search your config"
          onChange={typeSearch}
          value={state.term === null ? query : state.term}
        />
        <Spinner
          size={24}
          position="absolute"
          top={12}
          right={20}
          zIndex={state.searching ? 100 : -100}
        />
      </Pane>
      <Pane
        display={emptyResult() ? "inherit" : "none"}
        marginTop={50}
        textAlign="center"
      >
        <BanCircleIcon color="muted" size={80} />
        <Heading size={700}> Sorry, no result found</Heading>
        <Text> What your search unfortunately not found or doesn't exist</Text>
      </Pane>
      <Pane marginTop={50} display={emptyResult() ? "none" : "inherit"}>
        <ResultGroup
          name="Config"
          results={state.results.configs}
          linkTo={({ name, namespace }) => `/config/${namespace}/${name}`}
        />
        <ResultGroup
          name="Collections"
          results={state.results.collections}
          linkTo={() => "/"}
        />
        <ResultGroup
          name="schemas"
          results={state.results.schemas}
          linkTo={({ name }) => `/schema/${name}`}
        />
      </Pane>
    </Pane>
  );
}
