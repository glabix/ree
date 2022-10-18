import * as vscode from 'vscode'
import { getPackageEntryPath, getPackageObjectFromCurrentPath, getProjectRootDir } from '../utils/packageUtils'
import { loadPackagesSchema } from '../utils/packagesUtils'
import { PackageFacade } from '../utils/packageFacade'
import { loadObjectSchema } from '../utils/objectUtils'

const fs = require('fs')
const path = require('path')
const TAB_LENGTH = 2

export function updatePackageDeps(
  { objectName,
    toPackageName,
    fromPackageName,
    currentFilePath
   } : {
      objectName: string,
      fromPackageName: string
      toPackageName: string
      currentFilePath: string
    }
  ) { 
    getFileFromManager(currentFilePath).then(currentFile => {
      updateObjectLinks(currentFile, objectName, fromPackageName, toPackageName)
    })
}

function getFileFromManager(filePath: string): Thenable<vscode.TextDocument> {
  const textDocs = vscode.workspace.textDocuments

  
  if (textDocs.map(t => t.fileName).includes(filePath)) {
    return new Promise(resolve => resolve(textDocs.filter(t => t.fileName === filePath)[0]))
  } else {
    return vscode.workspace.openTextDocument(vscode.Uri.parse(filePath)).then((f: vscode.TextDocument) => { return f }) 
  }
}

function updatePackageDependsOn(currentFile: vscode.TextDocument, fromPackageName: string): Thenable<boolean> {
  const packageFacade = getPackageObjectFromCurrentPath(currentFile.fileName)
  if (packageFacade.deps().map(d => d.name).includes(fromPackageName)) { return }

  const packageEntryPath = getPackageEntryPath(currentFile.fileName)
  const packageFile = getFileFromManager(packageEntryPath)

  return packageFile.then(file => {  
    const text = file.getText()
    const textArray = text.split('\n')
    let dependsOnLine = 0
    let dependsOnStartPos = 0
    let dependsOnEndPos = 0
    let dependsOnStr = `depends_on :${fromPackageName}`
  
    let insertLine = 0
    let insertCharacter = 0
    
    let packageDefinitionLine = 0
    let packageDefinitionStartPos = 0
    let packageDefinitionEndPos = 0
    
    packageDefinitionLine = textArray.findIndex((s) => !!s.match(/package/))
    packageDefinitionStartPos = textArray[packageDefinitionLine].indexOf('package')
    packageDefinitionEndPos = textArray[packageDefinitionLine].length
  
    let insertStr = ''
    if (textArray[packageDefinitionLine].match(/\sdo/)) {
      const isDependsOnPresent = textArray.reverse().some((s, index) => {
        dependsOnLine = textArray.length - index - 1
        dependsOnStartPos = s.indexOf('depends')
        dependsOnEndPos = s.length
        return !!s.match(/depends_on/)
      })
  
      if (isDependsOnPresent) {
        insertStr = `\n${' '.repeat(dependsOnStartPos)}${dependsOnStr}`
        insertLine = dependsOnLine
        insertCharacter = dependsOnEndPos
      } else {
        insertStr = `\n${' '.repeat(packageDefinitionStartPos * TAB_LENGTH)}${dependsOnStr}\n`
        insertLine = packageDefinitionLine
        insertCharacter = packageDefinitionEndPos
      }
    } else {
      insertStr = ` do\n${' '.repeat(packageDefinitionStartPos * TAB_LENGTH)}${dependsOnStr}\n${' '.repeat(packageDefinitionStartPos)}end\n`
      insertLine = packageDefinitionLine
      insertCharacter = packageDefinitionEndPos
    }
  
  
    return editDocument(file, insertLine, insertCharacter, insertStr)
  })
}

function updateObjectLinks(
  currentFile: vscode.TextDocument,
  objectName: string,
  fromPackageName: string,
  toPackageName: string
  ): Thenable<boolean> | null {
  const packagesSchema = loadPackagesSchema(currentFile.fileName)
  const currentPackage = packagesSchema.packages.find(p => p.name === toPackageName)
  const projectRootDir = getProjectRootDir(currentFile.fileName)
  const packageFacade = new PackageFacade(path.join(projectRootDir, currentPackage.schema))
  const currentObjName = currentFile.fileName.split('/').slice(-1)[0].split('.rb')[0]
  const object = packageFacade.objects().find(o => o.name === currentObjName)
  const currentObject = loadObjectSchema(path.join(projectRootDir, object.schema))
  if (currentObject.links.find(l => l.target === objectName)) { return }

  let lineNumber = 0
  let startCharPos = 0
  let endCharPos = 0
  let text = currentFile.getText()

  text.split('\n').some((s, index) => {
    lineNumber = index
    endCharPos = s.length
    startCharPos = s.indexOf('fn') === -1 ? s.indexOf('bean') : s.indexOf('fn')
    return !!s.match(/(fn|bean)\s\:[A-Za-z\_]+/)
  })

  let insertLinkString = `\n${' '.repeat(startCharPos * TAB_LENGTH)}link :${objectName}`
  if (fromPackageName !== toPackageName) {
    insertLinkString += `, from: :${fromPackageName}`
  }
  let endInsertStr = ''

  if (text.split('\n')[lineNumber].match(/\sdo/)) {
    endInsertStr = insertLinkString
  } else {
    endInsertStr = ` do${insertLinkString}\n${' '.repeat(startCharPos)}end\n`
  }

  return editDocument(currentFile, lineNumber, endCharPos, endInsertStr)
}

function editDocument(currentFile: vscode.TextDocument, line: number, character: number, insertString: string): Thenable<boolean> {
  return vscode.workspace.openTextDocument(vscode.Uri.parse(currentFile.fileName)).then((f: vscode.TextDocument) => {
    const edit = new vscode.WorkspaceEdit()

    edit.insert(f.uri, new vscode.Position(line, character), insertString)
    return vscode.workspace.applyEdit(edit)
  }).then(() => {
    return currentFile.save()
  })
}

function spliceSlice(str: string, index: number, count: number, add: string) {
  return str.slice(0, index) + (add || "") + str.slice(index + count)
}