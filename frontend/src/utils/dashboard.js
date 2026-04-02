export const dashboardRangeOptions = [
  { value: "LAST_30_DAYS", label: "Last 30 days" },
  { value: "LAST_90_DAYS", label: "Last 90 days" },
  { value: "LAST_180_DAYS", label: "Last 180 days" },
  { value: "ALL_TIME", label: "All time" },
];

export function resolveDownloadFilename(headers, fallback) {
  const disposition = headers?.["content-disposition"];
  const match = disposition?.match(/filename="(.+?)"/i);
  return match?.[1] ?? fallback;
}

export function triggerFileDownload(blob, fileName) {
  const objectUrl = window.URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = objectUrl;
  anchor.download = fileName;
  document.body.append(anchor);
  anchor.click();
  anchor.remove();
  window.URL.revokeObjectURL(objectUrl);
}
