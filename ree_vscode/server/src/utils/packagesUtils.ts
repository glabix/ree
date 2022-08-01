import { PACKAGES_SCHEMA_FILE } from './constants'
import { getProjectRootDir } from './packageUtils'

const path = require('path')
const fs = require('fs')

let cachedPackages: IPackagesSchema | undefined = undefined
let packagesCtime: number | null = null
let cachedGemPackages: Object | null = null
let cachedGems: ICachedGems = {}

interface ExecCommand {
  message: string
  code: number
}

class ExecCommandError extends Error {
  constructor(m: string) {
    super(m)

    // Set the prototype explicitly.
    Object.setPrototypeOf(this, ExecCommandError.prototype)
  }
}

interface ICachedGems {
  [key: string]: string | undefined
}


export interface IPackagesSchema {
  packages: IPackageSchema[]
  gemPackages: IGemPackageSchema[]
}

export interface IPackageSchema {
  name: string
  schema: string
}
export interface IGemPackageSchema {
  gem: string
  name: string
  schema: string
}

export function loadPackagesSchema(currentPath: string): IPackagesSchema | undefined {
  const root = getProjectRootDir(currentPath)
  if (!root) { return }

  const schemaPath = path.join(root, PACKAGES_SCHEMA_FILE)
  if (!fs.existsSync(schemaPath)) { return }

  const ctime = fs.statSync(schemaPath).ctimeMs

  if (packagesCtime != ctime || !cachedPackages) {
    packagesCtime = ctime

    return cachedPackages = parsePackagesSchema(
      fs.readFileSync(schemaPath, { encoding: 'utf8' }), root
    )
  } else {
    return cachedPackages
  }
}

export function getGemPackageSchemaPath(gemPackageName: string): string | undefined {
  const gemPath = getGemDir(gemPackageName)
  if (!gemPath) { return }

  const gemPackage = getCachedGemPackage(gemPackageName)
  if (!gemPackage) { return }

  return path.join(gemPath, gemPackage.schema)
}

export function getCachedGemPackage(gemPackageName: string): IGemPackageSchema | undefined {
  if (!cachedPackages) { return }

  const gemPackage = cachedPackages?.gemPackages.find(p => p.name === gemPackageName)
  if (!gemPackage) { return }

  return gemPackage
}

export function getGemDir(gemPackageName: string): string | undefined {
  if (!cachedPackages) { return }

  const gemPackage = cachedPackages?.gemPackages.find(p => p.name === gemPackageName)
  if (!gemPackage) { return }

  const gemDir = cachedGems[gemPackage.gem]
  if (!gemDir) { return }

  return path.join(gemDir.trim(), 'lib', gemPackage.gem)
}

function parsePackagesSchema(data: string, rootDir: string) : IPackagesSchema | undefined {
  try {
    const schema = JSON.parse(data) as any;
    const obj = {} as IPackagesSchema

    obj.packages = schema.packages.map((p: any) => {
      return {name: p.name, schema: p.schema} as IPackageSchema
    })

    obj.gemPackages = schema.gem_packages.map((p: any) => {
      return {gem: p.gem, name: p.name, schema: p.schema} as IGemPackageSchema
    })

    // cache gemPackages by gem
    cachedGemPackages = groupBy(obj.gemPackages, 'gem')
    if (cachedGemPackages) {
      Object.keys(cachedGemPackages).flatMap((gem: string) => {
        let gemPathCommandResult = execBundlerGetGemPath(gem, rootDir)
        if (!gemPathCommandResult) { return [] }

        if (gemPathCommandResult.code === 0) {
          cachedGems[gem] = gemPathCommandResult.message
        } else {
          throw new ExecCommandError(`BundlerError: ${gemPathCommandResult.message}`)
        }
      })
    }

    return obj
  } catch (err) {
    console.error(err)
    return undefined
  }
}

function execBundlerGetGemPath(gemName: string, rootDir: string): ExecCommand | undefined {
  try {
    let spawnSync = require('child_process').spawnSync
    const argsArr = ['show', gemName]

    let child = spawnSync(
      'bundle',
      argsArr,
      { cwd: rootDir }
    )

    return {
      message: child.status === 0 ? child.stdout.toString() : child.stderr.toString(),
      code: child.status
    }
  } catch(e) {
    return undefined
  }
}

function groupBy(data: Array<any>, key: string) {
  return data.reduce((storage, item) => {
      let group = item[key]
      storage[group] = storage[group] || []
      storage[group].push(item)
      return storage
  }, {})
}
