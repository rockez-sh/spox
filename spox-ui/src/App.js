import 'bootstrap/dist/css/bootstrap.min.css';
import {
  Pane
} from 'evergreen-ui';
import {
  BrowserRouter as Router,
  Switch,
  Route,
} from "react-router-dom";

import HomePage from './pages/HomePage'
import ConfigPage from './pages/ConfigPage'
import CollectionPage from './pages/CollectionPage'
import SchemaPage from './pages/SchemaPage'

function App() {
  return (
    <Router>
      <div className="App">
        <Pane display="flex"
          alignItems="center"
          justifyContent="center"
          paddingTop={50}
          >
          <Pane width={700}>
            <Switch>
              <Route path="/config"><ConfigPage/></Route>
              <Route path="/collection"><CollectionPage/></Route>
              <Route path="/schema/:name?"><SchemaPage/></Route>
              <Route path="/"> <HomePage/> </Route>
            </Switch>
          </Pane>
        </Pane>
      </div>
    </Router>
  );
}

export default App;
