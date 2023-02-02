import { debugOutputClientChannel, debugOutputServerChannel } from "../extension"

export function capitilizeString(string: string): string {
  const firstLetter = string.toLowerCase().charAt(0).toUpperCase()
  return string.replace(string[0], firstLetter)
}

export function snakeToCamelCase(string: string): string {
  return string
    .split("_")
    .map((word) => capitilizeString(word))
    .join("")
}

export function toSnakeCase(string: string): string {
  return string.match(/([A-Z])/g).reduce(
    (str, c) => str.replace(new RegExp(c), '_' + c.toLowerCase()),
    string
  )
  .substring((string.slice(0, 1).match(/([A-Z])/g)) ? 1 : 0)
}

export function currentTimeStamp(): string {
  return new Date().toISOString()
}

export function logDebugClientMessage(message: string) {
  debugOutputClientChannel.appendLine(`[CLIENT][${currentTimeStamp()}] ${message}`)
}

export function logDebugServerMessage(message: string) {
  debugOutputServerChannel.appendLine(`[SERVER]${message}`)
}