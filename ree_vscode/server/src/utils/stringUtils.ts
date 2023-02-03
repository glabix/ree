import { connection } from ".."

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
  let str = string.match(/([A-Z])/g)
  if (str) {
    return str.reduce(
      (str, c) => str.replace(new RegExp(c), '_' + c.toLowerCase()),
      string
    )
    .substring((string.slice(0, 1).match(/([A-Z])/g)) ? 1 : 0)
  }

  return string
}

export function currentTimeStamp(): string {
  return new Date().toISOString()
}

export enum LogLevel {
  info = 'INFO',
  warn = 'WARN',
  error = 'ERROR'
}

export function buildLogMessage(message: string, level: LogLevel): string {
  return `[${level}][${currentTimeStamp()}] ${message}`
}

export function logInfoMessage(message: string) {
  sendDebugServerLogToClient(message, LogLevel.info)
}

export function logWarnMessage(message: string) {
  sendDebugServerLogToClient(message, LogLevel.warn)
}

export function logErrorMessage(message: string) {
  sendDebugServerLogToClient(message, LogLevel.error)
}

export function sendDebugServerLogToClient(message: string, level: LogLevel) {
  connection.sendNotification('reeLanguageServer/serverLog', buildLogMessage(message, level))
}