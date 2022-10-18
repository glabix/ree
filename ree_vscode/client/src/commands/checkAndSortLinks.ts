import * as vscode from 'vscode'
import { loadPackagesSchema } from "../utils/packagesUtils";
const fs = require('fs')

export function checkAndSortLinks(filePath: string, packageName: string) {
  const file = fs.readFileSync(filePath, { encoding: 'utf8' })
  const links = []
  let lineNumber = 0
  let firstLinkLineNumber = 0
  let linkCount = 0
  const content = file.split("\n")
  content.forEach((line) => {
    if (line.match(/link\s/)) {
      links.push(line)
      linkCount += 1
      
      if (linkCount === 1) { firstLinkLineNumber = lineNumber }
    }
    lineNumber += 1
  })

  const linksWithFileName = links.filter(l => l.match(/link\s(\"|\')/))
  const linksWithSymbolName = links.filter(l => !linksWithFileName.includes(l))
  const sortedLinksWithFileName = linksWithFileName.sort()
  const sortedLinksWithSymbolName = linksWithSymbolName.sort()
  const allSorted = [...sortedLinksWithSymbolName, ...sortedLinksWithFileName]
  const linkNameRegexp = /link\s(?<name>((\:?\w+)|(\"\w.+\")))/
  const importRegexp = /(import\:\s)?(\-\>\s?\{(?<import>.+)\})/
  const contentWithoutLinks = content.slice(firstLinkLineNumber + allSorted.length).join("\n")
  const sorted = allSorted.filter(link => {
    let linkName = link.match(linkNameRegexp)?.groups?.name
    let linkNameIsSymbol = linkName[0] === ":"
    let imports = link.match(importRegexp)?.groups?.import

    if (linkNameIsSymbol && contentWithoutLinks.match(RegExp(`${linkName.slice(1)}`))?.length > 0) { return link }
    if (!imports) { return }

    // check imports
    let isImportsPresent = imports.split('&').map(e => e.trim()).some((el) => {
      return contentWithoutLinks.match(RegExp(`${el}`))?.length > 0
    })

    if (isImportsPresent) { return link }

    return
  })

  // return if all links is used and already sorted
  if (sorted.join("\n") === links.join("\n")) { return }

  content.splice(firstLinkLineNumber, allSorted.length, ...sorted)  
  const data = content.join("\n")

  fs.writeFileSync(filePath, data, {encoding: 'utf8'})
}