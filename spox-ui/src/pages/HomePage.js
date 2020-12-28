import MainMenu from "../MainMenu";
import {Pane, Heading, TextInput, Text, Table, Button, EditIcon, SearchInput, Spinner} from 'evergreen-ui';
import { useState, useEffect } from 'react';
import {
  notEmpty,
  isEmpty,
  apiCall
} from '../Utils';


const DELAY_SEARCH = 500;
var typingTimer ;
function ResultGroup({name, results}) {
    console.log("ResultGroup: isEmpty(results)", isEmpty(results), results)
    if (isEmpty(results)){
      return <div></div>
    }
    return <Pane marginBottom={20}>
            <Heading size={600}>{name}</Heading>
            <Pane paddingTop={20}>
            {results.map(({name},index)=>{
             return <Table.Row key={index} height={32}>
                <Table.TextCell  flexBasis={560} flexShrink={0} flexGrow={0}>
                  <Text size={500}>{name}</Text>
                </Table.TextCell>
                <Table.TextCell textAlign="right">
                  <Text size={12}><EditIcon size={11}/> Edit</Text>
                </Table.TextCell>
              </Table.Row>
            })}
            </Pane>
          </Pane>
}
export default function HomePage(){
    const [state, setState] = useState({
      engaged: false,
      typing: false,
      lastTyping: 0,
      searching: false,
      term: null,
      results: {
        configs: [],
        collections: [],
        schemas: []
      }
    })
    const {engaged} = state
    function setEngaged(){
      setState({...state, engaged: true});
    }
    function apiSearch(value){
      if(isEmpty(value)){
        return setState({...state, results: {
          configs: [],
          collections: [],
          schemas: []}
        })
      }

      setState({...state, searching: true})
      apiCall("/api/search", {
        method: 'POST',
        headers: {'Content-Type': 'application/json' },
        body: JSON.stringify({ keyword: value}),
      })
      .then(({status, json}) => {
        if(status == 200){
         setState({...state, searching: false, engaged: true, results: json.data})
        }
      })
    }
    function typeSearch(x){
      setState({...state, typing: true, lastTyping: Date.now()})
      clearTimeout(typingTimer);
      let value = x.target.value

      typingTimer = setTimeout(() => {
        let {lastTyping} = state
        let delta = Date.now() - lastTyping
        console.log(delta);
        if(delta >= DELAY_SEARCH){
          apiSearch(value);
        }
      }, DELAY_SEARCH)
    }

    return (
      <Pane marginTop={engaged ? 0 : 250}>
        <Pane display="flex">
          <Pane width="75%">
            <Heading size={900} marginBottom={30}>Spox</Heading>
          </Pane>
          <Pane width="25%" align="right">
            <MainMenu/>
          </Pane>
        </Pane>
        <Pane position="relative">
          <SearchInput width="100%" height={48} placeholder="Start Search your config" onChange={typeSearch} />
          <Spinner size={24} position="absolute" top={12} right={20} zIndex={state.searching ? 100 : -100}/>
        </Pane>
        <Pane marginTop={50}>
          <ResultGroup name="Config" results={state.results.configs}  />
          <ResultGroup name="Collections" results={state.results.collections}  />
          <ResultGroup name="schemas" results={state.results.schemas}  />
        </Pane>
      </Pane>
    )
  }