import { CompletionItem, CompletionItemKind } from 'vscode-languageserver'
import { Position } from 'vscode-languageserver-textdocument'
import { documents } from '../documentManager'
import { findTokenNodeInTree, forest, mapLinkQueryMatches } from '../forest'
import { QueryMatch, Query, SyntaxNode, Tree, QueryCapture } from 'web-tree-sitter'
import { getCachedIndex, getGemDir, IPackagesSchema, ICachedIndex, loadPackagesSchema } from '../utils/packagesUtils'
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

    const currentPackageName = getPackageNameFromPath(filePath)
    if (!currentPackageName) { return defaultCompletion }

    const projectRootDir = getProjectRootDir(filePath)
    if (!projectRootDir) { return defaultCompletion }

    const objectName = getObjectNameFromPath(filePath)
    if (!objectName) { return defaultCompletion }

    const index = getCachedIndex()

    const doc = documents.get(uri)
    let tree = forest.getTree(uri)
    if (!tree) {
      tree = forest.createTree(uri, doc.getText())
    }

    // filter that already using
    const query = tree.getLanguage().query(
      `(
        (link
           link_name: (_) @name) @link
        (#select-adjacent! @link)
      ) `
    ) as Query

    const links = mapLinkQueryMatches(query.matches(tree.rootNode))

    const constantsQueryCaptures = tree.getLanguage().query(
      `(
        (constant) @call
        (#match? @call "(${links.filter(l => l.imports.length > 0).map(l => l.imports).flat().join("|")})$")
      )`
    ).captures(tree.rootNode)

    const tokenNode = findTokenNodeInTree(token, tree)

    // first we check if we have any matching nodes
    if (tokenNode) {
      if (index && index?.classes) {
        const constantMethods = this.getConstantMethodsFromIndex(tokenNode, index, constantsQueryCaptures)
        if (constantMethods.length > 0) {
          return constantMethods
        }
      }
    }
  
    // if there are no matching nodes, show package objects and constants
    const currentProjectPackages = this.getCurrentProjectPackages(packagesSchema, projectRootDir, currentPackageName, filePath)
    const gemPackageObjects = this.getGemPackageObjects(packagesSchema, projectRootDir, currentPackageName, filePath)
    let allItems = currentProjectPackages.concat(...gemPackageObjects)

    // add constants
    if (index && index?.classes) {
      const constantsItems = this.getConstantsFromIndex(index, projectRootDir, currentPackageName, filePath)
      allItems = allItems.concat(...constantsItems)
    }

    if (allItems.length === 0) { return defaultCompletion }

    let linkNames = links.map(l => l.name)
    return allItems.filter(obj => !linkNames.includes(obj.label) || obj.label !== objectName)
  }

  private static getCurrentProjectPackages(
    packagesSchema: IPackagesSchema,
    projectRootDir: string,
    currentPackage: string,
    filePath: string): CompletionItem[] {
    return packagesSchema.packages.map((pckg) => {
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
  }

  private static getGemPackageObjects(
    packagesSchema: IPackagesSchema,
    projectRootDir: string,
    currentPackageName: string,
    filePath: string
    ): CompletionItem[] {
    return packagesSchema.gemPackages.map((pckg) => {
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
              toPackageName: currentPackageName,
              currentFilePath: filePath,
              type: CompletionItemKind.Method,
              projectRootDir: gemPath || projectRootDir
            }
          }
        )
      )

      return objects
    }).flat()
  }

  private static getConstantsFromIndex(
    index: ICachedIndex,
    projectRootDir: string,
    currentPackageName: string,
    filePath: string
    ): CompletionItem[] {
    return Object.keys(index.classes).map((k: string) => {
      return index['classes'][k].map(c => {
        return {
          label: k,
          labelDetails: {
            description: `from: :${c.package}`
          },
          kind: CompletionItemKind.Class,
          data: {
            objectName: k,
            fromPackageName: c.package,
            toPackageName: currentPackageName,
            projectRootDir: projectRootDir,
            currentFilePath: filePath,
            type: CompletionItemKind.Class,
            linkPath: c.path
          }
        } as CompletionItem
      })
    }).flat()
  }

  private static getConstantMethodsFromIndex(
    tokenNode: SyntaxNode,
    index: ICachedIndex,
    constantsQueryCaptures: QueryCapture[]
    ): CompletionItem[] {
    // check if we inside constant instantiation
    let constantNodeText = tokenNode?.parent?.parent?.firstChild?.text
    let classes = Object.keys(index.classes)
    if (constantNodeText && classes.includes(constantNodeText)) {
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

    const findParentNodeWithType = (node: SyntaxNode | null, type: string, returnParent: boolean = false): SyntaxNode | null => {
      if (node === null) { return node }
      if (!node.parent) { return node }
      if (node.parent.type === type) { return returnParent ? node.parent : node }

      return findParentNodeWithType(node.parent, type, returnParent)
    }

    // trying to match call-nodes (ex SomeClass.new().some_method_call)
    let constantCallQueryMatches = constantsQueryCaptures.filter(e => e.node?.parent?.type === 'call')
    let constantsFromIndexNodes = constantCallQueryMatches.filter(e => classes.includes(e.node.text)).map(e => e.node)
    let matchedNodes = constantsFromIndexNodes.filter(node => {
      // if tokenNode inside constantNode parent
      // ex: SomeClass.new(id: 1).*tokenNode* or SomeClass.new(id: 1).build.*tokenNode*
      let nodeHaveTokenNode = !!findParentNodeWithType(node, 'assignment', false)?.children.find(c => c.equals(tokenNode)) ||
                              !!findParentNodeWithType(node, 'method', false)?.children.find(c => c.equals(tokenNode))
      if (nodeHaveTokenNode) {
        return true
      } else {
        // check if we have assignment node, then check if assignment lhs is same as tokenNode
        const assignmentNode = findParentNodeWithType(node, 'assignment', true)
        if (assignmentNode) {
          return !!tokenNode?.parent?.text.match(RegExp(`^${assignmentNode?.firstChild?.text}\.`))
        }
      }
    })
    if (matchedNodes.length > 0) {
      return matchedNodes.map(n => {
        return index.classes[n.text].map(c => {
          return c.methods.map(m => {
            return {
              label: m.name,
              details: `${snakeToCamelCase(c.package)}`,
              kind: CompletionItemKind.Field,
            } as CompletionItem
          })
        }).flat()
      }).flat()
    }

    return [] as CompletionItem[]
  }
}

