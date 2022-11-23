import { connection } from '..'
import { PACKAGES_SCHEMA_FILE } from './constants'
import { getProjectRootDir } from './packageUtils'
import { getReeVscodeSettings } from './reeUtils'

const path = require('path')
const fs = require('fs')

let cachedPackages: IPackagesSchema | undefined = undefined
let packagesCtime: number | null = null
let cachedGemPackages: Object | null = null
let cachedGems: ICachedGems = {}
let cachedIndex: ICachedIndex = {}

export function getCachedIndex(): ICachedIndex {
  return cachedIndex
}

export function setCachedIndex(value: ICachedIndex) {
  cachedIndex = value
}

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

interface ICachedIndex {
  [classes: string]: {
    [key: string]: [
      {
        path: string,
        package: string,
        methods: [
          {
            name: string,
            location: number
          }
        ]
      }
    ]
  }
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

export function cacheGemPaths(rootDir: string): Promise<ExecCommand | undefined> {
  return execBundlerGetGemPaths(rootDir)
}

export function cacheIndex(rootDir: string): Promise<ExecCommand | undefined> {
  return execGetReeIndex(rootDir)
}

export function loadPackagesSchema(currentPath: string): IPackagesSchema | undefined {
  const root = getProjectRootDir(currentPath)
  if (!root) { return }

  
  const schemaPath = path.join(root, PACKAGES_SCHEMA_FILE)
  if (!fs.existsSync(schemaPath)) { return }

  const ctime = fs.statSync(schemaPath).ctimeMs

  if (packagesCtime !== ctime || !cachedPackages) {
    packagesCtime = ctime

    if (!cachedIndex || (cachedIndex && Object.keys(cachedIndex).length === 0)) {
      cacheIndex(root).then(r => {
        try {
          if (r) {
            if (r.code === 0) {
              cachedIndex = JSON.parse(r.message)
            } else {
              cachedIndex = {}
              connection.window.showErrorMessage(r.message)
            }
          }
        } catch(e: any) {
          cachedIndex = {}
          connection.window.showErrorMessage(e.toString())
        }
      })
    }

    // TODO: move to server setup after initialization
    cacheGemPaths(root).then((r) => {
      const gemPathsArr = r?.message.split("\n")
      gemPathsArr?.map((path) => {
        let splitedPath = path.split("/")
        let name = splitedPath[splitedPath.length - 1].replace(/\-(\d+\.?)+/, '')

        cachedGems[name] = path
      })

      cachedPackages = parsePackagesSchema(
        fs.readFileSync(schemaPath, { encoding: 'utf8' }), root
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

    return obj
  } catch (err) {
    console.error(err)
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

async function execGetReeIndex(rootDir: string): Promise<ExecCommand | undefined> {
  try {
    const {dockerAppDirectory, dockerContainerName, dockerPresented} = getReeVscodeSettings(rootDir)

    if (dockerPresented) { 
      return spawnCommand([
        'docker', [
          'exec',
          '-i',
          '-e',
          'REE_SKIP_ENV_VARS_CHECK=true',
          '-w',
          dockerAppDirectory,
          dockerContainerName,
          'bundle',
          'exec',
          'ree',
          'gen.index_project'
        ]
      ])
    } else {
      return spawnCommand([
        'bundle', [
          'exec',
          'ree',
          'gen.index_project'
        ],
        { cwd: rootDir }
      ])
    }
  } catch(e) {
    console.error(e)
    return new Promise(() => undefined)
  }
}

async function spawnCommand(args: Array<any>): Promise<ExecCommand | undefined> {
  try {
    let spawn = require('child_process').spawn
    const child = spawn(...args)
    let message = ''

    for await (const chunk of child.stdout) {
      message += chunk
    }

    for await (const chunk of child.stderr) {
      message += chunk
    }

    const code: number  = await new Promise( (resolve, reject) => {
      child.on('close', resolve);
    })

    return {
      message: message,
      code: code
    }
  } catch(e) {
    console.error(`Error. ${e}`)
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
