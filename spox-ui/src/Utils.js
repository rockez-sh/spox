import { toaster } from "evergreen-ui";

import { useLocation } from "react-router-dom";

function formState(state, setState, form_state_attribute = "form_data") {
  return function (attribute, getter) {
    return function (e) {
      let value = null;
      if (typeof getter === "function") value = getter(e);
      else {
        if (e.target) value = e.target.value;
        else if (e.value) value = e.value;
        else value = e;
      }

      let form_data = { ...state[form_state_attribute], [attribute]: value };
      let newState = { ...state, [form_state_attribute]: form_data };
      setState(newState);
      return Promise.resolve(value);
    };
  };
}
function raiseError(status) {
  throw new Error(status);
}
function toasterError(error) {
  toaster.danger(error.message);
}

function humanizeString(string) {
  return string
    .replace("_", " ")
    .split(" ")
    .map((word, i) => {
      if (i > 0) return word;
      let chars = word.split("");
      let first = chars.shift(1).toUpperCase();
      chars.unshift(first);
      return chars.join("");
    })
    .join(" ");
}

function apiCall(path, opt, callback, failCallback) {
  let options = notEmpty(opt) ? opt : {};

  return fetch("http://localhost:5001" + path, options)
    .then(async (resp) => {
      let json = await resp.json();
      let status = resp.status;
      if (typeof callback == "object") {
        if (callback[status] !== undefined) {
          callback[status](json);
        } else {
          failCallback(resp);
        }
      } else if (typeof callback == "function") {
        callback(status, json);
      } else {
        return Promise.resolve({ status, json });
      }
    })
    .catch((error) => {
      failCallback(error, true);
    });
}

function notEmpty(value) {
  return !isEmpty(value);
}

function isEmpty(value) {
  if (value === undefined || value === null || value === "") return true;
  else if (typeof value.length === "number" && value.length === 0) {
    return true;
  } else {
    return false;
  }
}

function useQuery() {
  return new URLSearchParams(useLocation().search);
}

export {
  formState,
  humanizeString,
  toasterError,
  raiseError,
  apiCall,
  notEmpty,
  isEmpty,
  useQuery,
};
