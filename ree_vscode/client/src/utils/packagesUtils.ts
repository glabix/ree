
import * as vscode from 'vscode'
import { PACKAGES_SCHEMA_FILE } from '../core/constants'
import { getCurrentProjectDir } from './fileUtils'
import { getProjectRootDir } from './packageUtils'
import { spawnCommand } from './reeUtils'

const path = require('path')
const fs = require('fs')

let cachedIndex: ICachedIndex
let getNewIndexRetryCount: number = 0
const MAX_GET_INDEX_RETRY_COUNT = 5

export function getCachedIndex(): ICachedIndex {
  if (!cachedIndex || (isCachedIndexIsEmpty())) {
    getNewProjectIndex()
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

export function getNewProjectIndex() {
  if (getNewIndexRetryCount > MAX_GET_INDEX_RETRY_COUNT) { return }

  const root = getCurrentProjectDir()
  if (!root) { return }

  cacheProjectIndex(root).then(r => {
    try {
      if (r) {
        if (r.code === 0) {
          cachedIndex = JSON.parse(r.message)
          getNewIndexRetryCount = 0
        } else {
          cachedIndex = <ICachedIndex>{}
          getNewIndexRetryCount += 1
          vscode.window.showErrorMessage(`GetProjectIndexError: ${r.message}`)
        }
      }
    } catch(e: any) {
      cachedIndex = <ICachedIndex>{}
      getNewIndexRetryCount += 1
      vscode.window.showErrorMessage(e.toString())
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
          vscode.window.showErrorMessage(`GetGemPathsError: ${r.message.toString()}`)
        }
      }
    })
  })  
}

export let cachedPackages: IPackagesSchema | undefined = undefined
export function setCachedPackages(packagesSchema: IPackagesSchema) {
  cachedPackages = packagesSchema
}

/* eslint-disable @typescript-eslint/naming-convention */
interface ExecCommand {
  message: string
  code: number
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

interface GemPath {
  [key: string]: string | undefined
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

async function execGetReeProjectIndex(rootDir: string): Promise<ExecCommand | undefined> {
  try {
    const dockerPresented = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('presented') as boolean
    const dockerContainerName = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('containerName') as string
    const dockerAppDirectory = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('appDirectory') as string

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
    const dockerPresented = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('presented') as boolean
    const dockerContainerName = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('containerName') as string
    const dockerAppDirectory = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('appDirectory') as string

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

function groupBy(data: Array<any>, key: string) {
  return data.reduce((storage, item) => {
      let group = item[key]
      storage[group] = storage[group] || []
      storage[group].push(item)
      return storage
  }, {})
}
