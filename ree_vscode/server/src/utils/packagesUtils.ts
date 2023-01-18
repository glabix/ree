import { connection } from '..'
import { PACKAGES_SCHEMA_FILE } from './constants'
import { getPackageEntryPath, getProjectRootDir } from './packageUtils'
import { getReeVscodeSettings } from './reeUtils'

const path = require('path')
const fs = require('fs')
const url = require('url')

let cachedIndex: ICachedIndex
let getNewIndexRetryCount: number = 0
const MAX_GET_INDEX_RETRY_COUNT = 5

export function getCachedIndex(): ICachedIndex {
  if (!cachedIndex || (isCachedIndexIsEmpty())) {
    getNewIndex()
  }

  return cachedIndex
}

export function setCachedIndex(value: ICachedIndex) {
  cachedIndex = value
}

export function isCachedIndexIsEmpty(): boolean {
  if (!cachedIndex) { return true }
  if (cachedIndex && Object.keys(cachedIndex).length > 0) { return false }

  return true
}

export function getNewIndex() {
  if (getNewIndexRetryCount > MAX_GET_INDEX_RETRY_COUNT) { return }

  connection.workspace.getWorkspaceFolders().then(v => {
    return v?.map(folder => folder)
  }).then(v => {
    if (v) { 
      const folder = v[0]
      const root = url.fileURLToPath(folder.uri)

      cacheProjectIndex(root).then(r => {
        try {
          if (r) {
            if (r.code === 0) {
              cachedIndex = JSON.parse(r.message)
              getNewIndexRetryCount = 0
            } else {
              cachedIndex = <ICachedIndex>{}
              getNewIndexRetryCount += 1
              connection.window.showErrorMessage(`GetProjectIndexError: ${r.message}`)
            }
          }
        } catch(e: any) {
          cachedIndex = <ICachedIndex>{}
          getNewIndexRetryCount += 1
          connection.window.showErrorMessage(e.toString())
        }
      }).then(() => {
        cacheGemPaths(root.toString()).then((r) => {
          if (r) {
            if (r.code === 0) {
              const gemPathsArr = r?.message.split("\n")
              let index = getCachedIndex()
              if (isCachedIndexIsEmpty()) { index ??= <ICachedIndex>{} }
              index.gem_paths ??= {}
    
              gemPathsArr?.map((path) => {
                let splitedPath = path.split("/")
                let name = splitedPath[splitedPath.length - 1].replace(/\-(\d+\.?)+/, '')
        
                index.gem_paths[name] = path
              })
    
              setCachedIndex(index)
            } else {
              connection.window.showErrorMessage(`GetGemPathsError: ${r.message.toString()}`)
            }
          }
        })
      })
    }
  })
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

/* eslint-disable @typescript-eslint/naming-convention */
interface GemPath {
  [key: string]: string | undefined
}

export interface ICachedIndex {
  classes: {
    [key: string]: IIndexedElement[]
  },
  objects: {
    [key: string]: IIndexedElement[]
  },
  packages_schema: IPackagesSchema,
  gem_paths: GemPath
}

export interface IIndexedElement {
  path: string,
  package: string,
  methods: [
    {
      name: string,
      parameters?: { name: number, required: string }[]
      location: number
    }
  ]
}

export interface IPackagesSchema {
  packages: IPackageSchema[]
  gem_packages: IGemPackageSchema[]
}

export interface IPackageSchema {
  name: string
  schema_rpath: string
  entry_rpath: string
  tags: string[]
  objects: IObject[]
}
export interface IGemPackageSchema {
  gem: string
  name: string
  schema_rpath: string
  entry_rpath: string
  objects: IObject[]
}

export interface IObject {
  name: string
  schema_rpath: string
  file_rpath: string
  mount_as: string
  factory: string | null
  methods: IObjectMethod[]
  links: IObjectLink[]
}

export interface IMethodArg {
  arg: string
  type: string
}

export interface IObjectMethod {
  doc: string
  throws: string[]
  return: String | null
  args: IMethodArg[]
}

export interface IObjectLink {
  target: string,
  package_name: string,
  as: string,
  imports: string[]
}
/* eslint-enable @typescript-eslint/naming-convention */

export function cacheGemPaths(rootDir: string): Promise<ExecCommand | undefined> {
  return execBundlerGetGemPaths(rootDir)
}

export function cacheProjectIndex(rootDir: string): Promise<ExecCommand | undefined> {
  return execGetReeProjectIndex(rootDir)
}

export function cacheFileIndex(rootDir: string, filePath: string): Promise<ExecCommand | undefined> {
  return execGetReeFileIndex(rootDir, filePath)
}

export function getGemPackageSchemaPath(gemPackageName: string): string | undefined {
  const gemPath = getGemDir(gemPackageName)
  if (!gemPath) { return }

  const gemPackage = getCachedGemPackage(gemPackageName)
  if (!gemPackage) { return }

  return path.join(gemPath, gemPackage.schema_rpath)
}

export function getCachedGemPackage(gemPackageName: string): IGemPackageSchema | undefined {
  if (!cachedIndex) { return }

  const gemPackage = cachedIndex?.packages_schema.gem_packages.find(p => p.name === gemPackageName)
  if (!gemPackage) { return }

  return gemPackage
}

export function getGemDir(gemPackageName: string): string | undefined {
  if (!cachedIndex) { return }

  const gemPackage = cachedIndex?.packages_schema.gem_packages.find(p => p.name === gemPackageName)
  if (!gemPackage) { return }

  const gemDir = cachedIndex.gem_paths[gemPackage.gem]
  if (!gemDir) { return }

  return path.join(gemDir.trim(), 'lib', gemPackage.gem)
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

async function execGetReeProjectIndex(rootDir: string): Promise<ExecCommand | undefined> {
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

async function execGetReeFileIndex(rootDir: string, filePath: string): Promise<ExecCommand | undefined> {
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
          'gen.index_file',
          filePath
        ]
      ])
    } else {
      return spawnCommand([
        'bundle', [
          'exec',
          'ree',
          'gen.index_file',
          filePath
        ],
        { cwd: rootDir }
      ])
    }
  } catch(e) {
    console.error(e)
    return new Promise(() => undefined)
  }
}

export function updateFileIndex(uri: string) {
  let filePath = url.fileURLToPath(uri)
  const isSpecFile = !!filePath.split("/").pop().match(/\_spec/)
  if (isSpecFile) { return }

  let root = getProjectRootDir(filePath)

  let rFilePath = path.relative(root, filePath)
  if (root) {
    let packageEntryFilePath = getPackageEntryPath(filePath)
    if (!packageEntryFilePath) { return }

    // check that we're inside a package
    let relativePackagePathToCurrentFilePath = path.relative(
      packageEntryFilePath.split("/").slice(0, -1).join("/"),
      filePath
    )
    if (relativePackagePathToCurrentFilePath.split('/').slice(0) === '..' && !isSpecFile) { return }

    let dateInFile = new Date(parseInt(filePath.split("/").pop().split("_")?.[0]))
    if (!isNaN(dateInFile?.getTime())) { return }

    cacheFileIndex(root,rFilePath).then(r => {
      if (r) {
        if (r.code === 0) {
          try {
            let index = getCachedIndex()
            let newIndexForFile = JSON.parse(r.message)
            if (Object.keys(newIndexForFile).length === 0) { return }

            let classConst = Object.keys(newIndexForFile)?.[0]
            // TODO: update index for objects/mappers
            if (index.classes) {
              const oldIndex = index.classes[classConst].findIndex(v => v.path.match(RegExp(`${rFilePath}`)))
              if (oldIndex !== -1) {
                index.classes[classConst][oldIndex].methods = newIndexForFile[classConst].methods
                index.classes[classConst][oldIndex].package = newIndexForFile[classConst].package
              } else {
                index.classes[classConst].push(newIndexForFile)
              }
            }

            setCachedIndex(index)
          } catch (e: any) {
            connection.window.showErrorMessage(e)
          }
        } else {
          connection.window.showErrorMessage(r.message)
        }
      }
    })
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
      child.on('close', resolve)
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
