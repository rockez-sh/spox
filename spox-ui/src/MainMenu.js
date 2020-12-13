import {
  Pane,
  Position,
  Popover,
  Menu,
  PlusIcon,
  SymbolTriangleDownIcon,
  WrenchIcon,
  PropertiesIcon,
  DocumentIcon
} from 'evergreen-ui';

import {
  Link
} from "react-router-dom";

export default function MainMeu (argument) {
  return (
    <Popover
      position={Position.BOTTOM_RIGHT}
      content={
        <Menu>
          <Menu.Group>
            <Menu.Item is={Link} to="/config" icon={WrenchIcon}>New Config</Menu.Item>
            <Menu.Item is={Link} to="/collection" icon={PropertiesIcon}>New Collection</Menu.Item>
            <Menu.Item is={Link} to="/schema" icon={DocumentIcon}> New Schema </Menu.Item>
          </Menu.Group>
        </Menu>
      }
    >
      <Pane cursor="pointer" width={50}>
        <PlusIcon size={25} marginTop={10}/>
        <SymbolTriangleDownIcon size={10}/>
      </Pane>
    </Popover>
    )
}