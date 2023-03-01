import { connection } from '..'
import { getPackageEntryPath, getProjectRootDir, getPackagesSchemaPath } from './packageUtils'
import { getReeVscodeSettings } from './reeUtils'
import { TAB_LENGTH } from './constants'
import { logErrorMessage, logInfoMessage, logWarnMessage } from './stringUtils'
import { SyntaxNode } from 'web-tree-sitter'

const path = require('path')
const fs = require('fs')
const url = require('url')

export const BASIC_TYPES = [
  'Date', 'Time', 'Numeric', 'Integer',
  'String', 'FalseClass', 'TrueClass',
  'NilClass', 'Symbol', 'Module', 'Class', 'Hash'
]

const ARG_REGEXP = /(?<key>(\:[A-Za-z_]*\??)|(\"[A-Za-z_]*\"))\s\=\>\s(?<value>(\w*)?(\[(.*?)\])?)/
const ARG_REGEXP_GLOBAL = /(?<key>(\:[A-Za-z_]*\??)|(\"[A-Za-z_]*\"))\s\=\>\s(?<value>(\w*)?(\[(.*?)\])?)/g

let cachedIndex: ICachedIndex
let getNewIndexRetryCount: number = 0
const MAX_GET_INDEX_RETRY_COUNT = 5

enum Semaphore {
  open = 0,
  closed = 1
}

let getProjectIndexSemaphore: Semaphore = Semaphore.open
let getPackageIndexSemaphore: Semaphore = Semaphore.open
let getFileIndexSemaphore: Semaphore = Semaphore.open

let packagesSchemaCtime: number | null = null
export function getPackagesSchemaCtime(): number | null {
  return packagesSchemaCtime
}
export function setPackagesSchemaCtime(value: number) {
  packagesSchemaCtime = value
}
export function isPackagesSchemaCtimeChanged(): boolean {
  const root = getCachedProjectRoot()
  const oldCtime = getPackagesSchemaCtime()
  const newCtime = fs.statSync(getPackagesSchemaPath(root)).ctimeMs
  return oldCtime !== newCtime
}

let packageSchemasCtimes: { [key: string]: number } = {}
export function getPackageSchemaCtime(packageName: string) {
  return packageSchemasCtimes[packageName]
}
export function setPackageSchemaCtime(packageName: string, ctime: number) {
  packageSchemasCtimes[packageName] = ctime
}
export function isPackageSchemaCtimeChanged(pckg: IPackageSchema): boolean {
  const root = getCachedProjectRoot()
  const oldCtime = getPackageSchemaCtime(pckg.name)
  const pckgSchemaPath = pckg.schema_rpath
  if (!fs.existsSync(pckgSchemaPath)) {
    logErrorMessage(`Package.schema.json for ${pckg.name} package is not exists`)
    return true
  }

  const newCtime = fs.statSync(path.join(root, pckgSchemaPath)).ctimeMs
  const isChanged = oldCtime !== newCtime
  return isChanged
}

let projectRoot: string
export function getCachedProjectRoot(): string {
  return projectRoot
}
export function setCachedProjectRoot(value: string) {
  projectRoot = value
}

export function getCachedIndex(): ICachedIndex {
  if (!cachedIndex || (isCachedIndexIsEmpty())) {
    getNewProjectIndex()
  }

  if (cachedIndex && !isCachedIndexIsEmpty()) {
    let root = getCachedProjectRoot()
    if (isPackagesSchemaCtimeChanged()) {
      
      logInfoMessage('Packages.schema.json is changed')
      getNewProjectIndex()
      calculatePackagesSchemaCtime(root)
      return cachedIndex
    }

    if (cachedIndex.packages_schema && cachedIndex.packages_schema.packages) {
      let changedPackages = cachedIndex.packages_schema.packages.filter(p => isPackageSchemaCtimeChanged(p))
      if (changedPackages.length > 0) {
        logInfoMessage('Some packages schemas is changed')
        changedPackages.forEach(p => logInfoMessage(`Package ${p.name} schema is changed`))
      }
      changedPackages.forEach(pckg => {
        getPackageIndex(root, pckg.name)
      })
    }
  }

  return cachedIndex
}

export function getPackageIndex(root: string, packageName: string) {
  if (getPackageIndexSemaphore === Semaphore.closed) { return }

  getPackageIndexSemaphore = Semaphore.closed
  cachePackageIndex(root, packageName).then(r => {
    try {
      if (r) {
        if (r.code === 0) {
          let newPackageIndex = JSON.parse(r.message)
          logInfoMessage(`Got Package index for ${packageName}`)
          const packageSchema = newPackageIndex.package_schema as IPackageSchema
          const classes = newPackageIndex.classes as ICachedIndex["classes"]
          const objects = newPackageIndex.objects as ICachedIndex["objects"]

          if (classes && Object.keys(classes).length > 0) {
            let classKeys = Object.keys(classes)
            classKeys.forEach(key => {
              if (cachedIndex.classes[key]) {
                let newValues = classes[key]
                newValues.forEach(v => {
                  const oldIndex = cachedIndex.classes[key].findIndex(e => e.path === v.path)
                  if (oldIndex !== -1) {
                    cachedIndex.classes[key][oldIndex] = v
                  } else {
                    cachedIndex.classes[key].push(v)
                  }
                })
              } else {
                cachedIndex.classes[key] = classes[key]
              }
            })
          }

          if (objects && Object.keys(objects).length > 0) {
            let objectsKeys = Object.keys(objects)
            objectsKeys.forEach(key => {
              if (cachedIndex.objects[key]) {
                let newValues = objects[key]
                newValues.forEach(v => {
                  const oldIndex = cachedIndex.objects[key].findIndex(e => e.path === v.path)
                  if (oldIndex !== -1) {
                    cachedIndex.objects[key][oldIndex] = v
                  } else {
                    cachedIndex.objects[key].push(v)
                  }
                })
              } else {
                cachedIndex.objects[key] = objects[key]
              }
            })
          }

          calculatePackageSchemaCtime(root, packageName)
          let refreshedPackages = cachedIndex.packages_schema.packages.filter(p => p.name !== packageName)
          refreshedPackages.push(packageSchema)
          cachedIndex.packages_schema.packages = refreshedPackages
          getPackageIndexSemaphore = Semaphore.open
        } else {
          logErrorMessage(`GetPackageIndexError: ${r.message}`)
          getPackageIndexSemaphore = Semaphore.open
        }
      }
    } catch(e: any) {
      logErrorMessage(e.toString())
      connection.window.showErrorMessage(e.toString())
      getPackageIndexSemaphore = Semaphore.open
    }
  })
}

export function setCachedIndex(value: ICachedIndex) {
  cachedIndex = value
}

export function isCachedIndexIsEmpty(): boolean {
  if (!cachedIndex) { return true }
  if (cachedIndex && Object.keys(cachedIndex).length > 0 && cachedIndex.packages_schema) { return false }

  return true
}

export function getNewProjectIndex(manual = false, showNotification = false) {
  if (getNewIndexRetryCount > MAX_GET_INDEX_RETRY_COUNT && !manual) {
    logWarnMessage('getNewProjectIndex reached max limit')
    return
  }

  if (getProjectIndexSemaphore === Semaphore.closed) { return }

  getProjectIndexSemaphore = Semaphore.closed
  connection.workspace.getWorkspaceFolders().then(v => {
    return v?.map(folder => folder)
  }).then(v => {
    if (v) { 
      const folder = v[0]
      const root = url.fileURLToPath(folder.uri)
      let projectRoot = getProjectRootDir(root)
      if (projectRoot) {
        setCachedProjectRoot(projectRoot)
      }

      cacheProjectIndex(root).then(r => {
        try {
          if (r) {
            if (r.code === 0) {
              cachedIndex = JSON.parse(r.message)
              calculatePackagesSchemaCtime(root)
              cachedIndex.packages_schema.packages.forEach(pckg => {
                calculatePackageSchemaCtime(root, pckg.name)
              })
              logInfoMessage('Got new Project Index')
              getNewIndexRetryCount = 0
              getProjectIndexSemaphore = Semaphore.open
            } else {
              logErrorMessage('Got error code when getting new Project index')
              if (isCachedIndexIsEmpty()) {
                logInfoMessage('Index is empty, set as empty object')
                cachedIndex = <ICachedIndex>{}
              }
              getNewIndexRetryCount += 1
              logErrorMessage(`GetProjectIndexError: ${r.message}`)
              getProjectIndexSemaphore = Semaphore.open
            }
          }
        } catch(e: any) {
          logErrorMessage('Catched some error when tried to get new Project index')
          if (isCachedIndexIsEmpty()) {
            logInfoMessage('Index is empty, set as empty object')
            cachedIndex = <ICachedIndex>{}
          }
          getNewIndexRetryCount += 1
          logErrorMessage(e.toString())
          connection.window.showErrorMessage(e.toString())
          getProjectIndexSemaphore = Semaphore.open
        }
      }).then(() => {
        cacheGemPaths(root.toString()).then((r) => {
          if (r) {
            if (r.code === 0) {
              logInfoMessage('Got Gem Paths')
              const gemPathsArr = r?.message.split("\n")
              if (isCachedIndexIsEmpty()) {
                logInfoMessage('Index is empty, set as empty object')
                cachedIndex ??= <ICachedIndex>{}
              }
              cachedIndex.gem_paths ??= {}
    
              gemPathsArr?.map((path) => {
                let splitedPath = path.split("/")
                let name = splitedPath[splitedPath.length - 1].replace(/\-(\d+\.?)+/, '')
        
                cachedIndex.gem_paths[name] = path
              })
              logInfoMessage('Gem Paths setted')
            } else {
              logErrorMessage(`GetGemPathsError: ${r.message.toString()}`)
              connection.window.showErrorMessage(`GetGemPathsError: ${r.message.toString()}`)
            }
          }
        })
      }).then(() => {
        if (showNotification) {
          connection.window.showInformationMessage("SERVER: Reindex is completed!")
        }
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
  arg_type: string
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

export function cachePackageIndex(rootDir: string, packageName: string): Promise<ExecCommand | undefined> {
  return execGetReePackageIndex(rootDir, packageName)
}

export function cacheFileIndex(rootDir: string, filePath: string): Promise<ExecCommand | undefined> {
  return execGetReeFileIndex(rootDir, filePath)
}

export function calculatePackagesSchemaCtime(root: string) {
  logInfoMessage('Trying to recalculate Packages.schema.json ctime')
  const packagesSchemaPath = getPackagesSchemaPath(root)
  if (packagesSchemaPath) {
    logInfoMessage('Packages.schema.json ctime recalculated')
    setPackagesSchemaCtime(fs.statSync(packagesSchemaPath).ctimeMs)
  }
}

export function calculatePackageSchemaCtime(root: string, packageName: string) {
  logInfoMessage(`Trying to recalculate Package.schema.json for ${packageName}`)
  if (!cachedIndex.packages_schema?.packages) { return }

  const pckg = cachedIndex.packages_schema.packages.find(p => p.name === packageName)
  if (!pckg) { return }

  let schemaAbsPath = path.join(root, pckg.schema_rpath)
  let time = fs.statSync(schemaAbsPath).ctimeMs
  logInfoMessage(`Package.schema.json for ${pckg.name} recalculated`)
  setPackageSchemaCtime(pckg.name, time)
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

async function execGetReePackageIndex(rootDir: string, packageName: string): Promise<ExecCommand | undefined> {
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
          'gen.index_package',
          packageName
        ]
      ])
    } else {
      return spawnCommand([
        'bundle', [
          'exec',
          'ree',
          'gen.index_package',
          packageName
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
  if (getFileIndexSemaphore === Semaphore.closed) { return }

  getFileIndexSemaphore = Semaphore.closed
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
            let index = cachedIndex
            let newIndexForFile = JSON.parse(r.message)
            if (Object.keys(newIndexForFile).length === 0) { return }

            let classConst = Object.keys(newIndexForFile)?.[0]
            if (index.classes) {
              const oldIndex = index.classes[classConst].findIndex(v => v.path.match(RegExp(`${rFilePath}`)))
              if (oldIndex !== -1) {
                index.classes[classConst][oldIndex].methods = newIndexForFile[classConst].methods
                index.classes[classConst][oldIndex].package = newIndexForFile[classConst].package
              } else {
                index.classes[classConst].push(newIndexForFile)
              }
            }
            getFileIndexSemaphore = Semaphore.open
          } catch (e: any) {
            logErrorMessage(e.toString())
            connection.window.showErrorMessage(e.toString())
            getFileIndexSemaphore = Semaphore.open
          }
        } else {
          logErrorMessage(`CacheFileIndexError: ${r.message}`)
          getFileIndexSemaphore = Semaphore.open
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

    const code: number  = await new Promise( (resolve, _) => {
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

export function buildObjectArguments(obj: IObject, tokenNode?: SyntaxNode | null): string {
  if (obj.methods[0]) {
    const method = obj.methods[0]

    if (tokenNode?.nextSibling?.type === 'argument_list') { return obj.name }
    if (method.args.length === 0) { return `${obj.name}` }
    if (method.args.length === 1) { return `${obj.name}(${mapObjectArgument(method.args[0])})`}
    if (method.args.every(arg => {
      return [...BASIC_TYPES, 'Block'].includes(arg.type) ||
              arg.type.startsWith('ArrayOf') ||
              arg.type.startsWith('SplatOf') ||
              arg.type.startsWith('Nilor') ||
              arg.type.startsWith('Or')
            })
    ) {
      return `${obj.name}(${method.args.map(arg => mapObjectArgument(arg)).join(', ')})`
    }

    return `${obj.name}(\n${method.args.map(arg => `${' '.repeat(TAB_LENGTH)}${mapObjectArgument(arg)}`).join(',\n')}\n)`
  } else {
    return `${obj.name}`
  }
}

function getHashArgs(str: string): string {
  const matches = str.match(/(\{|Ksplat\[)(?<body>.*)(\}|\])/)
  if (matches?.groups?.body) {
    const body = matches.groups.body
    const eachArg = body.match(ARG_REGEXP_GLOBAL)
    if (!eachArg || eachArg.length === 0) { return str }

    const keyValueMatches = eachArg.map(e => e.match(ARG_REGEXP))
    if (!keyValueMatches || keyValueMatches.length === 0) { return str }

    const keyValueArrs = keyValueMatches.map(e => [e?.groups?.key?.replace(/\:/, ''), e?.groups?.value])
    if (keyValueArrs.some(e => e.length === 0)) { return str }

    return `{\n${keyValueArrs.map(e => `${' '.repeat(TAB_LENGTH * 2)}${e[0]}: ${e[1]},\n`).join('')}${' '.repeat(TAB_LENGTH)}}`
  }
  return str
}

function mapObjectArgument(arg: IMethodArg): string {
  const index = cachedIndex

  if (arg.arg_type === 'key' || arg.arg_type === 'keyreq') {
    return `${arg.arg}:`
  }

  if (BASIC_TYPES.includes(arg.type)) { return arg.arg }

  if (
    (arg.type.startsWith("{") && arg.type.endsWith("}")) ||
    (arg.type.startsWith("Ksplat[") && arg.type.endsWith("]"))
  ){
    return getHashArgs(arg.type)
  }

  if (arg.type === "Block") { return `&${arg.arg}`}
  if (arg.type.startsWith("SplatOf")) { return `*${arg.arg}`}

  if (index && !isCachedIndexIsEmpty()) {
    if (index.classes && Object.keys(index.classes).includes(arg.type)) {
      return arg.arg
    }
  }

  return arg.arg
}

function groupBy(data: Array<any>, key: string) {
  return data.reduce((storage, item) => {
      let group = item[key]
      storage[group] = storage[group] || []
      storage[group].push(item)
      return storage
  }, {})
}
