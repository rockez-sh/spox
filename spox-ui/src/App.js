import {Pane, TextInput, Button, Heading} from 'evergreen-ui';

function App() {
  return (
    <div className="App">
      <Pane display="flex"
        alignItems="center"
        justifyContent="center"
        alignItems="center">
        <Pane width={700} paddingTop={40}>
          <Heading size={900} textAlign="center" marginBottom={30} >Spox</Heading>
          <TextInput width="100%" height={48} placeholder="Start Search your config" />
        </Pane>
      </Pane>
    </div>
  );
}

export default App;
