export function getApiErrorMessage(error, fallback = "Request failed.") {
  return error?.response?.data?.message || error?.message || fallback;
}
