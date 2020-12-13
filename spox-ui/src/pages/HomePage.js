import MainMenu from "../MainMenu";
import {Pane, Heading, TextInput} from 'evergreen-ui';

export default function HomePage(){
    return (
      <Pane marginTop={250}>
        <Pane display="flex">
          <Pane width="75%">
            <Heading size={900} marginBottom={30} >Spox</Heading>
          </Pane>
          <Pane width="25%" align="right">
            <MainMenu/>
          </Pane>
        </Pane>
        <TextInput width="100%" height={48} placeholder="Start Search your config" />
      </Pane>
    )
  }