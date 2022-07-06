
import * as vscode from 'vscode'
import { PACKAGES_SCHEMA_FILE } from '../core/constants'
import { getProjectRootDir } from './packageUtils'

const path = require('path')
const fs = require('fs')

let cachedPackages: IPackageSchema[] | undefined = undefined
let packagesCtime: number | null = null

export interface IPackageSchema {
  name: string
  schema: string
}

export function loadPackagesSchema(currentPath: string): IPackageSchema[] | undefined {
  const root = getProjectRootDir(currentPath)
  if (!root) { return }

  const schemaPath = path.join(root, PACKAGES_SCHEMA_FILE)
  if (!fs.existsSync(schemaPath)) { return }

  const ctime = fs.statSync(schemaPath).ctimeMs

  if (packagesCtime != ctime || !cachedPackages) {
    packagesCtime = ctime

    return cachedPackages = parsePackagesSchema(
      fs.readFileSync(schemaPath, { encoding: 'utf8' })
    )
  } else {
    return cachedPackages
  }
}

function parsePackagesSchema(data: string) : IPackageSchema[] | undefined {
  try {
    const schema = JSON.parse(data) as any;

    return schema.packages.map((p: any) => {
      return {name: p.name, schema: p.schema} as IPackageSchema
    })
  } catch (err) {
    console.log(err)
    vscode.window.showErrorMessage(`Error: Unable to parse ${PACKAGES_SCHEMA_FILE}`)
    return undefined
  }
}
