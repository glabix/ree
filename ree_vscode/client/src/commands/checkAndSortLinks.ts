import * as vscode from 'vscode'
import { forest } from '../utils/forest';
import { loadPackagesSchema } from "../utils/packagesUtils";
const fs = require('fs')

const linkNameRegexp = /link\s(?<name>((\:?\w+)|(\"\w.+\")))/
const importRegexp = /(import\:\s)?(\-\>\s?\{(?<import>.+)\})/
const asRegexp = /as\:\s\:(\w+)/

export function checkAndSortLinks(filePath: string, packageName: string) {
  const file = fs.readFileSync(filePath, { encoding: 'utf8' })
  const uri = vscode.Uri.parse(filePath)

  let tree = forest.getTree(uri.toString())
  if (!tree) {
    tree = forest.createTree(uri.toString(), file)
  }

  const query = tree.getLanguage().query(
    `(
      (link
         link_name: (_) @name) @link
      (#select-adjacent! @link)
    ) `
  )

  const queryMatches = query.matches(tree.rootNode)

  const offset = ' '.repeat(queryMatches[0].captures[0].node.startPosition.column)
  const firstLinkLineNumber = queryMatches[0].captures[0].node.startPosition.row
  const links = queryMatches.map(qm => {
    return { name: qm.captures[1].node.text, body: qm.captures[0].node.text }
  })
  const content = file.split("\n")
  if (links.length === 0) { return }

  const isMapper = !!content[firstLinkLineNumber-1]?.match(/mapper/)?.length
  const isDao = !!content[firstLinkLineNumber-1]?.match(/dao/)?.length

  const linksWithFileName = links.filter(l => l.name[0] === "\"" || l.name[0] === "\'")
  const linksWithSymbolName = links.filter(l => !linksWithFileName.includes(l))
  const sortedLinksWithFileName = linksWithFileName.sort(sortLinksByNameAsc)
  const sortedLinksWithSymbolName = linksWithSymbolName.sort(sortLinksByNameAsc)
  let allSorted = [...sortedLinksWithSymbolName, ...sortedLinksWithFileName]
  let sortedWithoutUnused = []

  // check uniq
  const uniqLinks = createLinksHash(allSorted)
  
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

  if (!isMapper && !isDao) {
    sortedWithoutUnused = allSorted.filter(link => {
      let linkName = link.name
      let linkNameIsSymbol = linkName[0] === ":"
      let imports = link.body.match(importRegexp)?.groups?.import
      let as = link.body.match(asRegexp)?.[1]
      let name = !!as ? as : linkName.slice(1)
  
      if (name.match(/db/)) { return link }

      // TODO: need to benchmark if we need to query all symbols with imports in one query
      // and then filter by results, rather than quering by one

      if (linkNameIsSymbol) {
        let nameUsage = tree.getLanguage().query(
          `(
            (call receiver: (identifier) @call)
            (#match? @call "${name}$")
          )
          (
            (call method: (identifier) @call)
            (#match? @call "${name}$")
          )
          (
            (identifier) @call
            (#match? @call "${name}$")
          )
          `
        ).matches(tree.rootNode)

        if (nameUsage.length > 0) { return link }
      }
      if (!imports) { return }
  
      // check imports
      let importUsage = tree.getLanguage().query(
        `(
          (constant) @call
          (#match? @call "(${imports.trim().split(' & ').join("|")})$")
        )`
      ).matches(tree.rootNode)
  
      if (importUsage.length > 1) { return link }
  
      return
    })
  } else {
    sortedWithoutUnused = allSorted
  } 

  // return if all links is used and already sorted
  if (sortedWithoutUnused.map(l => l.body).join("\n") === links.map(l => l.body).join("\n")) { return }

  const sortedWithOffset = sortedWithoutUnused.map(link => `${offset}${link.body}`)

  content.splice(
    firstLinkLineNumber,
    queryMatches.slice(-1)[0].captures[0].node.endPosition.row - queryMatches[0].captures[0].node.startPosition.row + 1
  )
  content.splice(firstLinkLineNumber, 0, ...sortedWithOffset)
  const data = content.join("\n")

  fs.writeFileSync(filePath, data, {encoding: 'utf8'})
}

function createLinksHash(links: Array<{name: string, body: string}>) {
  let uniqLinks = {}
  links.map((link, index) => {
    let linkName = link.name.replace(/\:|\"/, '').split("/").pop()
    let asName = link.body.match(asRegexp)?.[1]

    let name = !!asName ? asName : linkName
    if (!uniqLinks[name]) {
      uniqLinks[name] = {}
      uniqLinks[name]['count'] = 1
      uniqLinks[name]['indexes'] = [index]
    } else {
      uniqLinks[name]['count'] += 1
      uniqLinks[name]['indexes'].push(index)
    }
  })

  return uniqLinks
}

function sortLinksByNameAsc(a, b) {
  let cleanA = a.name.replace(/\"|\'|\:/, '')
  let cleanB = b.name.replace(/\"|\'|\:/, '')
  if (cleanA > cleanB) { return 1 }
  if (cleanA < cleanB) { return -1 }
  return 0
}