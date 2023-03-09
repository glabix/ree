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

enum LogLevel {
  info = 'INFO',
  warn = 'WARN',
  error = 'ERROR'
}

export function buildLogMessage(message: string, level: LogLevel): string {
  return `[${level}][${currentTimeStamp()}] ${message}`
}

export function logInfoMessage(message: string) {
  logDebugClientMessage(message, LogLevel.info)
}

export function logWarnMessage(message: string) {
  logDebugClientMessage(message, LogLevel.warn)
}

export function logErrorMessage(message: string) {
  logDebugClientMessage(message, LogLevel.error)
}

export function logDebugClientMessage(message: string, level: LogLevel) {
  debugOutputClientChannel.appendLine(buildLogMessage(message, level))
}

export function logDebugServerMessage(message: string) {
  debugOutputServerChannel.appendLine(`${message}`)
}

export function escapeRegExp(string: string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}