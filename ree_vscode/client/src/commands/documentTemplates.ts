import { RUBY_EXT } from "../core/constants"
import { getPackageNameFromPath, getProjectRootDir, getWorkingPackageDirPath } from "../utils/packageUtils"
import { snakeToCamelCase } from "../utils/stringUtils"

const fs = require('fs')
const path = require('path')

export function onCreatePackageFile(filePath: string) {
  const result = preconditions(filePath)

  if (!result.success) { return }

  const content = fs.readFileSync(filePath, { encoding: 'utf8' }).trim()
  if (content) { return }

  const variables = prepareVariables(filePath)
  if (!variables) { return }

  const rDir = path.relative(result.workDir, path.dirname(filePath))

  const templatePath = path.join(
    result.projectDir, '.vscode-ree', 'templates', rDir, 'template.rb'
  )

  if (!fs.existsSync(templatePath)) { return }
  const templateContent = fs.readFileSync(templatePath, { encoding: 'utf8' })

  const actualTemplateContent = templateContent
    .replace("PACKAGE_MODULE", variables.moduleName)
    .replace("PACKAGE_NAME", variables.packageName)
    .replace("OBJECT_CLASS", variables.className)
    .replace("OBJECT_NAME", variables.objectName)
  
  fs.appendFileSync(filePath, actualTemplateContent)
}

export function onRenamePackageFile(filePath: string) {
  const result = preconditions(filePath)
  if (!result.success) { return }

  const variables = prepareVariables(filePath)
  if (!variables) { return }

  let content = fs.readFileSync(filePath, { encoding: 'utf8' }).trim()

  const mClass = content.match(/class\s([^<\s]+).*/)

  if (mClass && mClass.length > 1) {
    const className = mClass[1]
    content = content.replace(`class ${className}`, `class ${variables.moduleName}::${variables.className}`)
  }

  const mObject = content.match(/(fn|bean|dao|enum|mapper)\s(:[^\s]+).*/)

  if (mObject && mObject.length > 1) {
    const fn = mObject[1]
    const objectName = mObject[2]
    content = content.replace(`${fn} ${objectName}`, `${fn} :${variables.objectName}`)
  }

  fs.writeFileSync(filePath, content, {encoding: 'utf8'})
}

interface ICheckResult {
  success: boolean
  workDir: string | null
  projectDir: string | null
}

function preconditions(filePath: string): ICheckResult  {
  const result: ICheckResult = {success: false, workDir: null, projectDir: null}

  const projectDir = getProjectRootDir(filePath)
  if (!projectDir) { return result }
  
  const ext = path.parse(filePath).ext
  if (ext !== RUBY_EXT) { return result }

  const workDir = getWorkingPackageDirPath(filePath)
  if (!workDir) { return result }
  if (filePath.indexOf(workDir) !== 0) { return result }

  return { success: true, workDir: workDir, projectDir: projectDir } as ICheckResult
}

export interface IVariables {
  moduleName: string
  packageName: string
  objectName: string
  className: string
}

export function prepareVariables(filePath: string): IVariables | undefined {
  let packageName = getPackageNameFromPath(filePath)
  if (!packageName) { return } 

  const moduleName = snakeToCamelCase(packageName) 
  const objectName = path.parse(filePath).name
  const className = snakeToCamelCase(objectName)

  return {moduleName, packageName, objectName, className} as IVariables
}
