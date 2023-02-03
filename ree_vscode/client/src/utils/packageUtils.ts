import * as vscode from 'vscode'
import { PACKAGES_SCHEMA_FILE, PACKAGE_DIR, PACKAGE_SCHEMA_FILE } from '../core/constants'
import { getPackageDir } from './fileUtils'
import { logErrorMessage } from './stringUtils'

const path = require("path")
const fs = require("fs")

export function getPackageNameFromPath(pathToFile: string): string | null {
  const packageSchemaPath = getPackageSchemaPath(
    path.dirname(pathToFile)
  )
  
  if (!packageSchemaPath) { return null }
  
  try {
    const schemaFile = JSON.parse(fs.readFileSync(packageSchemaPath).toString())

    if (schemaFile.name) {
      return schemaFile.name
    } else {
      return null
    }
  } catch(err) {
    console.log(err)
    logErrorMessage(`Error: Unable to parse ${PACKAGE_SCHEMA_FILE}`)
    vscode.window.showErrorMessage(`Error: Unable to parse ${PACKAGE_SCHEMA_FILE}`)
    return null
  }
}

export function getPackageSchemaPath(dirname: string): string | null {
  const schemaPath = path.join(dirname, PACKAGE_SCHEMA_FILE)

  if (fs.existsSync(schemaPath)) {
    return schemaPath
  }
  
  if (dirname === '/') {
    return null
  }

  return getPackageSchemaPath(
    path.resolve(dirname, "../")
  )
}

export function getPackagesSchemaPath(currentPath: string): string | null {
  const schemaPath = path.join(currentPath, PACKAGES_SCHEMA_FILE)

  if (fs.existsSync(schemaPath)) {
    return schemaPath
  }
  
  if (currentPath === '/') {
    return null
  }

  return getPackagesSchemaPath(
    path.resolve(currentPath, "../")
  )
}

export function getProjectRootDir(currentPath: string): string | null {
  const schemaPath = getPackagesSchemaPath(currentPath)

  if (!schemaPath) { return null }

  return path.dirname(schemaPath)
}

export function getPackageEntryPath(filePath: string) : string | null {
  const packageFilePath = path.join(
    getPackageDir(filePath),
    PACKAGE_DIR,
    getPackageNameFromPath(filePath)
  ) + ".rb"

  if (fs.existsSync(packageFilePath)) {
    return packageFilePath
  }

  return null
}

// Returns absolute working package dir. Ex.: ./bc/accounts/package/accounts
export function getWorkingPackageDirPath(filePath: string) : string | null {
  const dir = path.join(
    getPackageDir(filePath),
    PACKAGE_DIR,
    getPackageNameFromPath(filePath)
  )

  if (fs.existsSync(dir)) {
    return dir
  }

  return null
}

export enum Locale {
  en = 'en',
  ru = 'ru'
}
export function getLocalePath(filePath: string, locale: Locale): string {
  let packageEntry = getPackageEntryPath(filePath)
  let packageName = packageEntry.split('/').slice(-1)[0].split('.')[0]
  let packageDir = packageEntry.split('/').slice(0, -1)
  packageDir.push(packageName, 'locales', `${locale}.yml`)
  return packageDir.join('/')
}