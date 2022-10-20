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

  const linkNameRegexp = /link\s(?<name>((\:?\w+)|(\"\w.+\")))/
  const importRegexp = /(import\:\s)?(\-\>\s?\{(?<import>.+)\})/

  const linksWithFileName = links.filter(l => l.match(/link\s(\"|\')/))
  const linksWithSymbolName = links.filter(l => !linksWithFileName.includes(l))
  const sortedLinksWithFileName = linksWithFileName.sort()
  const sortedLinksWithSymbolName = linksWithSymbolName.sort()
  let allSorted = [...sortedLinksWithSymbolName, ...sortedLinksWithFileName]

  // check uniq
  let uniqLinks = {}
  allSorted.map((link, index) => {
    let linkNameMatch = link.match(linkNameRegexp)?.groups?.name
    let linkName = linkNameMatch.replace(/\:|\"/, '').split("/").pop()
    if (!uniqLinks[linkName]) {
      uniqLinks[linkName] = {}
      uniqLinks[linkName]['count'] = 1
      uniqLinks[linkName]['indexes'] = [index]
    } else {
      uniqLinks[linkName]['count'] += 1
      uniqLinks[linkName]['indexes'].push(index)
    }
  })

  const duplicates = Object.keys(uniqLinks).filter(key => uniqLinks[key]['count'] > 1)
  if (duplicates.length > 0) {
    const duplicateIndexes = []
    duplicates.forEach(key => {
        // get value and index of duplicate without imports
        let linkValues = uniqLinks[key]['indexes'].map(i => [allSorted[i], i])

        let duplicateLinks = linkValues.filter(link => {
            return !(!!link[0].match(importRegexp)?.groups?.import)
        })
        let indexes = duplicateLinks.map(el => el.pop())
        if (indexes.length === linkValues.length) {
          indexes = indexes.slice(1)
        }
        duplicateIndexes.push(...indexes)
    })

    duplicateIndexes.forEach(i => { allSorted[i] = null })
    allSorted = allSorted.filter(el => el !== null)
  }
  
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

  content.splice(firstLinkLineNumber, links.length)
  content.splice(firstLinkLineNumber, 0, ...sorted)
  const data = content.join("\n")

  fs.writeFileSync(filePath, data, {encoding: 'utf8'})
}