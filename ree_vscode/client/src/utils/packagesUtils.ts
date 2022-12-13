
import * as vscode from 'vscode'
import { PACKAGES_SCHEMA_FILE } from '../core/constants'
import { getProjectRootDir } from './packageUtils'
import { spawnCommand } from './reeUtils'

const path = require('path')
const fs = require('fs')

export let cachedPackages: IPackagesSchema | undefined = undefined
export function setCachedPackages(packagesSchema: IPackagesSchema) {
  cachedPackages = packagesSchema
}

let packagesCtime: number | null = null
let cachedGemPackages: Object | null = null

export let cachedGems: ICachedGems = {}
export function setCachedGems(gemName: string, gemPath: string) {
  cachedGems[gemName] = gemPath
}

interface ExecCommand {
  message: string
  code: number
}

interface ICachedGems {
  [key: string]: string | undefined
}

interface IPackagesSchema {
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

export function cacheGemPaths(rootDir: string): Promise<ExecCommand | undefined> {
  return execBundlerGetGemPaths(rootDir)
}

export function loadPackagesSchema(currentPath: string): IPackagesSchema | undefined {
  const root = getProjectRootDir(currentPath)
  if (!root) { return }

  const schemaPath = path.join(root, PACKAGES_SCHEMA_FILE)
  if (!fs.existsSync(schemaPath)) { return }

  const ctime = fs.statSync(schemaPath).ctimeMs

  if (packagesCtime !== ctime || !cachedPackages) {
    packagesCtime = ctime

    cacheGemPaths(root).then((r) => {
      const gemPathsArr = r?.message.split("\n")
      gemPathsArr?.map((path) => {
        let splitedPath = path.split("/")
        let name = splitedPath[splitedPath.length - 1].replace(/\-(\d+\.?)+/, '')

        setCachedGems(name, path)
      })

      setCachedPackages(
        parsePackagesSchema(
          fs.readFileSync(schemaPath, { encoding: 'utf8' }), root
        )
      )
    })
  }

  return cachedPackages
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

export function parsePackagesSchema(data: string, rootDir: string) : IPackagesSchema | undefined {
  try {
    const schema = JSON.parse(data) as any
    const obj = {} as IPackagesSchema

    obj.packages = schema.packages.map((p: any) => {
      return {name: p.name, schema: p.schema} as IPackageSchema
    })

    obj.gemPackages = schema.gem_packages.map((p: any) => {
      return {gem: p.gem, name: p.name, schema: p.schema} as IGemPackageSchema
    })

    // cache gemPackages by gem
    cachedGemPackages = groupBy(obj.gemPackages, 'gem')

    return obj
  } catch (err) {
    return undefined
  }
}

async function execBundlerGetGemPaths(rootDir: string): Promise<ExecCommand | undefined> {
  try {
    const argsArr = ['show', '--paths']

    return spawnCommand([
      'bundle',
      argsArr,
      { cwd: rootDir }
    ])
  } catch(e) {
    console.error(e)
    return new Promise(() => undefined)
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
