import * as vscode from 'vscode'
import { getPackageNameFromPath } from '../utils/packageUtils'
import { logErrorMessage } from '../utils/stringUtils'

export function getCurrentPackage(fileName?: string): string | null {
  // check if active file/editor is accessible

  let currentFileName = fileName || vscode.window.activeTextEditor.document.fileName

  if (!currentFileName) {
    logErrorMessage("Open any package file")
    vscode.window.showErrorMessage("Open any package file")
    return
  }

  // finding package
  let currentPackage = getPackageNameFromPath(currentFileName)

  if (!currentPackage) { return }

  return currentPackage
}
