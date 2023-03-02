import * as vscode from 'vscode'
import { Query } from 'web-tree-sitter'
import { forest, asRegexp, mapLinkQueryMatches, Link } from '../utils/forest'
const fs = require('fs')
const lodash = require('lodash')

export function checkAndSortLinks(filePath: string) {
  const file = fs.readFileSync(filePath, { encoding: 'utf8' })
  const uri = vscode.Uri.parse(filePath)

  let tree = forest.getTree(uri.toString())
  if (!tree) {
    tree = forest.createTree(uri.toString(), file)
  }

  const query = forest.language.query(
    `(
      (link
         link_name: (_) @name) @link
      (#select-adjacent! @link)
    ) `
  ) as Query

  const queryMatches = query.matches(tree.rootNode)
  if (queryMatches?.length === 0) { return }

  const offset = ' '.repeat(queryMatches[0].captures[0].node.startPosition.column)
  const firstLinkLineNumber = queryMatches[0].captures[0].node.startPosition.row
  const filteredQueryMatches = queryMatches.filter(m => m.captures[0].node.parent.equals(queryMatches[0].captures[0].node.parent))
  const links = mapLinkQueryMatches(filteredQueryMatches)

  const content = file.split("\n")
  if (links.length === 0) { return }

  const isMapper = !!content[firstLinkLineNumber - 1]?.match(/mapper/)?.length
  const isDao = !!content[firstLinkLineNumber - 1]?.match(/dao/)?.length

  const linksWithFileName = lodash.cloneDeep(links).filter(l => !l.isSymbol)
  const linksWithSymbolName = lodash.cloneDeep(links).filter(l => l.isSymbol)
  const sortedLinksWithFileName = linksWithFileName.sort(sortLinksByNameAsc)
  const sortedLinksWithSymbolName = linksWithSymbolName.sort(sortLinksByNameAsc)
  let allSorted = [...sortedLinksWithSymbolName, ...sortedLinksWithFileName] as Link[]
  let sortedWithoutUnused = []

  // check uniq
  // get all uniq strings, then if we have any duplicates by name, check for imports
  allSorted = [...new Map(allSorted.map(item =>
    [item['body'], item])).values()]

  const uniqLinks = createLinksHash(allSorted)

  const duplicates = Object.keys(uniqLinks).filter(key => uniqLinks[key]['count'] > 1)
  if (duplicates.length > 0) {
    const duplicateIndexes = []
    duplicates.forEach(key => {
      // get value and index of duplicate without imports
      let linkValues = uniqLinks[key]['indexes'].map(i => [allSorted[i], i])

      let duplicateLinks = linkValues.filter(link => {
        return (link[0].imports.length === 0) // get links that don't have imports
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
    let importsStrings = []
    let nameStrings = []
    allSorted.forEach(el => {
      if (el.isSymbol) { 
        !!el.as ? nameStrings.push(el.as) : nameStrings.push(el.name)
      }
      if (el.imports) { importsStrings.push(...el.imports) }
    })

    const linkUsageMatches = forest.language.query(
      `
        (
          (identifier) @call
          (#match? @call "(${nameStrings.join('|')})$")
        )
        (
          (constant) @call
          (#match? @call "(${importsStrings.join("|")})$")
        )
      `
    ).matches(tree.rootNode)

    linkUsageMatches.forEach(el => {
      let nodeText = el.captures[0].node.text
      if (nameStrings.includes(nodeText)) {
        nameStrings.splice(nameStrings.indexOf(nodeText), 1)
      }

      if (importsStrings.includes(nodeText)) {
        if (
          el.captures[0].node.parent.type === 'block' ||
          el.captures[0].node?.nextSibling?.text === '&' ||
          el.captures[0].node?.previousSibling?.text === '&'
        ) { return }

        if (importsStrings.indexOf(nodeText) !== -1) {
          importsStrings.splice(importsStrings.indexOf(nodeText), 1)
        }
      }
    })

    if (nameStrings.length > 0) {
      allSorted = allSorted.filter(l => {
        if (nameStrings.includes(l.name) || nameStrings.includes(l.as)) {
          if (l.imports.length > 0) { return true }
          return false
        } else {
          return true
        }
      })
    }

    if (importsStrings.length > 0) {
      const sortedImportsStrings = importsStrings.sort()
      allSorted = allSorted.filter(l => {
        if (l.imports.length === 0) { return true }

        if (l.imports.every(i => sortedImportsStrings.includes(i))) {
          if (nameStrings.length > 0 && !nameStrings.includes(l.name) && l.isSymbol) {
            const newLinkBody = removeUnusedImportFromLink(l, importsStrings)

            if (!newLinkBody) { return false }

            l.body = newLinkBody
            return true
          }

          return false
        } else {
          const newLinkBody = removeUnusedImportFromLink(l, importsStrings)
          if (!newLinkBody) { return false }

          l.body = newLinkBody

          return true
        }
      })
    }
  }
  sortedWithoutUnused = allSorted

  // return if all links is used and already sorted
  if (sortedWithoutUnused.map(l => l.body).join("\n") === links.map(l => l.body).join("\n")) { return }

  const sortedWithOffset = sortedWithoutUnused.map(link => `${offset}${link.body}`)

  content.splice(
    firstLinkLineNumber,
    filteredQueryMatches.slice(-1)[0].captures[0].node.endPosition.row - filteredQueryMatches[0].captures[0].node.startPosition.row + 1
  )
  content.splice(firstLinkLineNumber, 0, ...sortedWithOffset)
  const data = content.join("\n")

  fs.writeFileSync(filePath, data, { encoding: 'utf8' })
  forest.updateTree(uri.toString(), data)
}

function createLinksHash(links: Array<{ name: string, body: string }>) {
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

export function sortLinksByNameAsc(a, b) {
  let cleanA = a.name.replace(/\"|\'|\:/, '')
  let cleanB = b.name.replace(/\"|\'|\:/, '')
  if (cleanA > cleanB) { return 1 }
  if (cleanA < cleanB) { return -1 }
  return 0
}

function removeUnusedImportFromLink(link: Link, importsStringsArr: string[]): string | null {
  const notAllUsedLinks = importsStringsArr.sort().filter(e => link.imports.sort().includes(e))
  if (notAllUsedLinks.length > 0) {
    // build new link string without unused
    let newLinkBody = ''
    if (link.isSymbol) {
      newLinkBody += `link :${link.name}`

      if (link.from) { newLinkBody += `, from: :${link.from}` }

      if (notAllUsedLinks.length !== link.imports.length) {
        newLinkBody += `, import: -> { ${link.imports.sort().filter(e => !notAllUsedLinks.includes(e)).join(' & ')} }`
      }
    } else {
      if (notAllUsedLinks.length === link.imports.length) { return null }
      
      newLinkBody += `link "${link.name}"`
      newLinkBody += `, -> { ${link.imports.sort().filter(e => !notAllUsedLinks.includes(e)).join(' & ')} }`
    }

    return newLinkBody
  }

  return link.body
}