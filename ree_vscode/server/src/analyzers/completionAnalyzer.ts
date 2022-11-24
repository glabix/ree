import { CompletionItem, CompletionItemKind } from 'vscode-languageserver'
import { Position } from 'vscode-languageserver-textdocument'
import { documents } from '../documentManager'
import { forest } from '../forest'
import { QueryMatch, Query, SyntaxNode } from 'web-tree-sitter'
import { getCachedIndex, getGemDir, loadPackagesSchema } from '../utils/packagesUtils'
import { getPackageNameFromPath, getProjectRootDir, getObjectNameFromPath } from '../utils/packageUtils'
import { PackageFacade } from '../utils/packageFacade'
import { extractToken } from '../utils/tokenUtils'
import { snakeToCamelCase } from '../utils/stringUtils'

const fs = require('fs')
const url = require('node:url')
const path = require('path')

export default class CompletionAnalyzer {
  public static analyze(uri: string, position: Position): CompletionItem[] {
    return this.getFilteredCompletionList(uri, position)
  }

  private static getFilteredCompletionList(uri: string, position: Position): CompletionItem[] {
    const defaultCompletion : CompletionItem[] = []
    let filePath = ''
    
    try {
      filePath = url.fileURLToPath(uri)
    } catch {
      return defaultCompletion
    }

    const token = extractToken(uri, position)

    const packagesSchema = loadPackagesSchema(filePath)
    if (!packagesSchema) { return defaultCompletion }

    const currentPackage = getPackageNameFromPath(filePath)
    const projectRootDir = getProjectRootDir(filePath)
    if (!projectRootDir) { return defaultCompletion }

    const objectName = getObjectNameFromPath(filePath)
    if (!objectName) { return defaultCompletion }

    const doc = documents.get(uri)
    let tree = forest.getTree(uri)
    if (!tree) {
      tree = forest.createTree(uri, doc.getText())
    }

    let index = getCachedIndex()

    let constantNode: any
    const cursor = tree.walk()
    const walk = (depth: number): void => {
      if (cursor.currentNode().text.match(`^${token}$`)) {
        constantNode = cursor.currentNode()
      }
      if (cursor.gotoFirstChild()) {
        do {
          walk(depth + 1)
        } while (cursor.gotoNextSibling())
        cursor.gotoParent()
      }
    }
    walk(0)
    cursor.delete()

    if (constantNode) {
      if (index && index?.classes) {
        let constantNodeText = constantNode?.parent?.parent?.children?.[0]?.text
        if (Object.keys(index.classes).includes(constantNodeText)) {
          return index.classes[constantNodeText].map(c => {
            return c.methods.map(m => {
              return {
                label: m.name,
                details: `${snakeToCamelCase(c.package)}`,
                kind: CompletionItemKind.Field,
              } as CompletionItem
            })
          }).flat()
        }
      }
    }
  
    const currentProjectPackages = packagesSchema.packages.map((pckg) => {
      let packageFacade = new PackageFacade(path.join(projectRootDir, pckg.schema))
      
      let objects = packageFacade.objects().map(obj => (
          
          {
            label: obj.name,
            labelDetails: {
              description: `from: ${pckg.name}`
            },
            kind: CompletionItemKind.Method,
            data: {
              objectSchema: obj.schema,
              fromPackageName: pckg.name,
              toPackageName: currentPackage,
              currentFilePath: filePath,
              type: CompletionItemKind.Method,
              projectRootDir: projectRootDir
            }
          } as CompletionItem
        )
      )

      return objects
    }).flat()

    // get gemPackages
    const gemPackageObjects = packagesSchema.gemPackages.map((pckg) => {
      let gemPath = getGemDir(pckg.name)
      if (!gemPath) { return [] }

      let packageFacade = new PackageFacade(path.join(gemPath, pckg.schema))
      
      let objects = packageFacade.objects().map(obj => (
          
          {
            label: obj.name,
            labelDetails: {
              description: `from: ${pckg.name}`
            },
            kind: CompletionItemKind.Method,
            data: {
              objectSchema: obj.schema,
              fromPackageName: pckg.name,
              toPackageName: currentPackage,
              currentFilePath: filePath,
              type: CompletionItemKind.Method,
              projectRootDir: gemPath || projectRootDir
            }
          }
        )
      )

      return objects
    }).flat()

    const objectsFromAllPackages = currentProjectPackages.concat(...gemPackageObjects)

    if (objectsFromAllPackages.length === 0) { return defaultCompletion }

    // filter that already using
    const query = tree.getLanguage().query(
      `(
        (link
           link_name: (_) @name) @link
        (#select-adjacent! @link)
      ) `
    ) as Query

    const queryMatches: QueryMatch[] = query.matches(tree.rootNode)
    const linkedDependencies = queryMatches.map(
      c => c.captures.filter(e => e.name === 'name')
      ).flat()
       .map(e => e.node)
       .map(e => e.text)
       .map(e => e.replace(':', ''))

    // add constants

    if (index && index?.classes) {
      Object.keys(index.classes).map((k: string) => {
        index['classes'][k].map(c => {
          let konstant = {
            label: k,
            labelDetails: {
              description: `from: :${c.package}`
            },
            kind: CompletionItemKind.Class,
            data: {
              objectName: k,
              fromPackageName: c.package,
              toPackageName: currentPackage,
              projectRootDir: projectRootDir,
              currentFilePath: filePath,
              type: CompletionItemKind.Class,
              linkPath: c.path
            }
          }
          objectsFromAllPackages.push(
            konstant
          )
        })
      })
    }

    return objectsFromAllPackages.filter(obj => !linkedDependencies.includes(obj.label) || obj.label !== objectName)
  }
}

