import { PACKAGE_DIR, RUBY_EXT, SPEC_EXT, SPEC_FOLDER } from './constants'
import { getPackageSchemaPath } from "./packageUtils"

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