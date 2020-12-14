import {
  Pane,
  Heading,
  WrenchIcon,
  TextInputField,
  TextareaField,
  Text
} from 'evergreen-ui'


export default function ConfigPage (argument) {
  return (
    <Pane>
      <Pane paddingBottom={10} borderBottom="muted" marginBottom={20}>
        <Heading size={700}><WrenchIcon/>  Config</Heading>
      </Pane>
      <Pane borderBottom="muted" marginBottom={20}>
        <Pane display="flex">
          <TextInputField
            label="Name"
            placeholder="Must be uniq per namespace, only alphanumeric & underscore are allowed"
            required={true}
            width="60%"
            marginRight={40}
          />
          <TextInputField
            label="Namespace"
            placeholder="namespace for your config"
            required={true}
            width="35%"
          />
        </Pane>
        <TextareaField
          label="Description"
          placeholder="A brief words what this config are for"
        />
      </Pane>
      <Pane>
        <Pane display="flex">
          <Text size={500} lineHeight="32px" marginRight={20}>Schema</Text>
        </Pane>
      </Pane>
    </Pane>
  )
}