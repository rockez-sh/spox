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
} from "evergreen-ui";
import { useState, useEffect, useCallback, useMemo } from "react";
import { notEmpty, isEmpty, apiCall, useQuery } from "../Utils";
import { useHistory } from "react-router-dom";

import { DELAY_SEARCH } from "./SearchPage";

var typingTimer;

export default function SearchPage() {
  let query = useQuery().get("q");
  let history = useHistory();

  const [state, setState] = useState({
    typing: false,
    lastTyping: 0,
    term: null,
  });

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

  return (
    <Pane marginTop={250}>
      <Pane display="flex">
        <Pane width="75%">
          <Heading size={900} marginBottom={30}>
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
          value={state.term}
        />
        <Spinner
          size={24}
          position="absolute"
          top={12}
          right={20}
          zIndex={state.searching ? 100 : -100}
        />
      </Pane>
    </Pane>
  );
}
