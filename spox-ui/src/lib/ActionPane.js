import {
  Pane,
  Button,
  SmallCrossIcon,
  SavedIcon
} from 'evergreen-ui';
import {
  Link
} from "react-router-dom";

export default function ActionPane({saving, onSubmit}){
  return <Pane>
      <Pane padding={20} marginTop={20} textAlign="right" background="tint1">
        <Button is={Link} to="/" iconBefore={SmallCrossIcon} marginRight={15}>Cancel</Button>
        <Button appearance="primary" onClick={onSubmit}  iconBefore={saving ? null : SavedIcon} isLoading={saving}>
          {saving ? 'Saving ...' : 'Save'}
        </Button>
      </Pane>
  </Pane>
}
