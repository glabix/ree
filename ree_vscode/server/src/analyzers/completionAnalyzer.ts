import { CompletionItem, CompletionItemKind } from 'vscode-languageserver'
import { Position } from 'vscode-languageserver-textdocument'
import { documents } from '../documentManager'
import { forest } from '../forest'
import { getGemDir, loadPackagesSchema } from '../utils/packagesUtils'
import { getPackageNameFromPath, getProjectRootDir } from '../utils/packageUtils'
import { PackageFacade } from '../utils/packageFacade'

const fs = require('fs')
const url = require('node:url')
const path = require('path')

export default class CompletionAnalyzer {
  public static analyze(uri: string, position: Position): CompletionItem[] {
    return this.getFilteredCompletionList(uri)
  }

  private static getFilteredCompletionList(uri: string, token?: string): CompletionItem[] {
    const defaultCompletion : CompletionItem[] = []
    let filePath = ''
    
    try {
      filePath = url.fileURLToPath(uri)
    } catch {
      return defaultCompletion
    }

    const packagesSchema = loadPackagesSchema(filePath)
    if (!packagesSchema) { return defaultCompletion }

    const currentPackage = getPackageNameFromPath(filePath)
    const projectRootDir = getProjectRootDir(filePath)
    if (!projectRootDir) { return defaultCompletion }
  
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
              projectRootDir: projectRootDir
            }
          }
        )
      )

      if (token) {
        objects = objects.filter(e => e.label.match(RegExp(`^${token}`)))
      }

      return objects
    }).flat()

    // get gemPackages
    const gemPackageObjects = packagesSchema.gemPackages.map((pckg) => {
      let gemPath = getGemDir(pckg.name)
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
              projectRootDir: gemPath || projectRootDir
            }
          }
        )
      )

      if (token) {
        objects = objects.filter(e => e.label.match(RegExp(`^${token}`)))
      }

      return objects
    }).flat()

    const objectsFromAllPackages = currentProjectPackages.concat(...gemPackageObjects)

    if (objectsFromAllPackages.length === 0) { return defaultCompletion }

    // filter that already using
    const doc = documents.get(uri)
    const tree = forest.createTree(uri, doc.getText())
    const query = tree.getLanguage().query(
      `(
        (link
           link_name: (_) @name) @link
        (#select-adjacent! @link)
      ) `
    )

    const queryMatches = query.matches(tree.rootNode)
    const linkedDependencies = queryMatches.map(
      c => c.captures.filter(e => e.name === 'name')
      ).flat()
       .map(e => e.node)
       .map(e => e.text)
       .map(e => e.replace(':', ''))

    // TODO: add to linked name of current file (ex. so I can't add build_user if I already in build_user)

    return objectsFromAllPackages.filter(obj => !linkedDependencies.includes(obj.label))
  }
}

