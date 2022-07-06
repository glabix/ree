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