export function buildCollectionParams(values) {
  const params = new URLSearchParams();

  Object.entries(values).forEach(([key, value]) => {
    if (value === null || value === undefined || value === "") {
      return;
    }
    params.set(key, String(value));
  });

  return params;
}

export function parseSortValue(sortValue, fallback) {
  const [sortBy, sortDir] = (sortValue || fallback).split(":");
  return { sortBy, sortDir };
}
