import {
  toaster
} from 'evergreen-ui';

function formState(state, setState, form_state_attribute="form_data") {
  return function(attribute, getter) {
    return function(e){
      let value = null
      if(getter)
        value = getter(e) ;
      else {
        if(e.target)
          value = e.target.value;
        else if(e.value)
          value = e.value;
      }

      let form_data = {...state[form_state_attribute], [attribute]: value}
      setState({...state, [form_state_attribute]: form_data})
    }
  }
}
function raiseError(status){
  throw new Error(status)
}
function toasterError(error) {
  toaster.danger(error.message)
}

function humanizeString(string) {
  return string
  .replace('_', ' ')
  .split(' ')
  .map((word, i) => {
    if(i > 0)
      return word;
    let chars = word.split('')
    let first = chars.shift(1).toUpperCase()
    chars.unshift(first)
    return chars.join('')
  }).join(' ')
}
export {
  formState,
  humanizeString,
  toasterError,
  raiseError
}