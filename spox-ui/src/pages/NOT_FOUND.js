import { Pane, Heading, Button } from "evergreen-ui";
import { Link } from "react-router-dom";

export default function NOTFOUND() {
  return (
    <Pane marginTop={250}>
      <Heading size={900} marginBottom={30}>
        404
      </Heading>
      <Button is={Link} to="/">
        {" "}
        Home{" "}
      </Button>
    </Pane>
  );
}
