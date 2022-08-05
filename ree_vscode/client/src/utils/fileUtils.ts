import * as vscode from 'vscode'
import { PACKAGES_SCHEMA_FILE, PACKAGE_DIR, RUBY_EXT, SPEC_EXT, SPEC_FOLDER } from '../core/constants'
import { getPackageSchemaPath, getProjectRootDir } from "./packageUtils"

const fs = require('fs')
const path = require("path")

// Extracts package root dir from any package file. Ex: bc/accounts
export function getPackageDir(filePath: string): string | null {
  const packageSchemaPath = getPackageSchemaPath(filePath)

  if (!packageSchemaPath) { return null }
  
  return path.dirname(packageSchemaPath)
}

// Converts absolute path to package relative path
export function getRelativePackageFilePath(filePath: string): string | null {
  const packageDir = getPackageDir(filePath)

  if (!packageDir) { return null }

  return path.relative(
    path.join(packageDir, PACKAGE_DIR), filePath
  )
}

// Converts absolute path to package root relative path
export function getFilePathRelativeToPackageRoot(filePath: string): string | null {
  const packageDir = getPackageDir(filePath)

  if (!packageDir) { return null }

  return path.relative(
    packageDir, filePath
  )
}

// Generates spec absolute path for specific packages file path
export function getSpecFilePath(filePath: string) : string | null {
  if (RUBY_EXT !== path.parse(filePath).ext) { return null }

  const packageDir = getPackageDir(filePath)

  if (!packageDir) { return null }

  const specDir = path.join(packageDir, SPEC_FOLDER)
  const relativeFilePath = getRelativePackageFilePath(filePath)

  if (!relativeFilePath) { return null }
  
  let specFilePath = path.join(specDir, relativeFilePath)
  const specName = path.parse(specFilePath).name + SPEC_EXT

  return path.join(path.dirname(specFilePath), specName)
}

export function getCurrentProjectDir (): string | null {
  if (!isReeProject()) {
    return null
  }

  if (!vscode.workspace.workspaceFolders) {
    return null
  }

  const activeEditor = vscode.window.activeTextEditor
  if (!activeEditor) { return vscode.workspace.workspaceFolders[0].uri.path }

  return getProjectRootDir(activeEditor.document.fileName)
}

export function isReeProject(): boolean {
  if (!vscode.workspace.workspaceFolders) {
    return false
  }
  let currentFilePath = null
  const activeEditor = vscode.window.activeTextEditor
  if (!activeEditor) {
    currentFilePath = vscode.workspace.workspaceFolders[0].uri.path
  } else {
    currentFilePath = activeEditor.document.fileName
  }

  const folder = getProjectRootDir(currentFilePath)
  if (!folder) { return false }

  const schemaPath = path.join(folder, PACKAGES_SCHEMA_FILE)

  if (fs.existsSync(schemaPath)) {
    return true
  } else {
    return false
  }
}