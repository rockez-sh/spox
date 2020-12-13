import {
  Pane,
  Heading,
  WrenchIcon
} from 'evergreen-ui'

export default function ConfigPage (argument) {
  return (
    <Pane>
      <Heading size={700}><WrenchIcon/>  Config</Heading>
    </Pane>
  )
}