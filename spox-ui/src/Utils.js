function formState(state, setState, form_state_attribute="form_data") {
  return function(attribute) {
    return function(e){
      let form_data = {...state[form_state_attribute], [attribute]: e.target.value}
      setState({...state, [form_state_attribute]: form_data})
    }
  }
}

export {formState}