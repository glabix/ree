import * as vscode from 'vscode'
import { PACKAGE_DIR, RUBY_EXT, SPEC_EXT } from '../core/constants'
import { openDocument } from '../utils/documentUtils'

import { getSpecFilePath, getPackageDir, getFilePathRelativeToPackageRoot, getCurrentProjectDir, getRelativePackageFilePath } from "../utils/fileUtils"
import { getPackageNameFromPath } from '../utils/packageUtils'
import { prepareVariables } from './documentTemplates'

const path = require('path')
const fs = require('fs')

const SPEC_REGEXP = /.*_spec.rb$/
const SPEC_TEMPLATE = `# frozen_string_literal: true

package_require('RELATIVE_FILE_PATH')

RSpec.describe MODULE_NAME::CLASS_NAME do
  link :OBJECT_NAME, from: :PACKAGE_NAME

  it {
    OBJECT_NAME()
  }
end`

export function goToSpec() {
  if (!vscode.window.activeTextEditor) { return }

  const projectDir = getCurrentProjectDir()
  if (!projectDir) { return }

  const currentFilePath = vscode.window.activeTextEditor.document.fileName
  const ext = path.parse(currentFilePath).ext

  if (ext !== RUBY_EXT) { return }

  if (SPEC_REGEXP.test(currentFilePath)) {
    goFromSpecFile(currentFilePath)
    return
  }

  const specFilePath = getSpecFilePath(currentFilePath)

  if (!specFilePath) { return }

  if (fs.existsSync(specFilePath)) {
    openDocument(specFilePath)
    return
  }

  const filename = path.parse(currentFilePath).name
  const specsFolder = path.join(path.dirname(specFilePath), filename)

  if (fs.existsSync(specsFolder)) {
    const files = fs.readdirSync(specsFolder) as string[]

    if (files.length) {
      const $promise = vscode.window.showQuickPick(
        files,
        {placeHolder: "Select spec file:"}
      )

      $promise.then(
        (file: string | undefined) => {
          if (!file) { return }

          openDocument(path.join(specsFolder, file))
        }
      )
    } else {
      promptCreateSpecFile(projectDir, currentFilePath, specFilePath)
    }
  } else {
    promptCreateSpecFile(projectDir, currentFilePath, specFilePath)
  }
}

function goFromSpecFile(currentFilePath: string) {
  let filename = path.basename(currentFilePath)
  filename = filename.replace(SPEC_EXT, RUBY_EXT)

  const filePath = path.join(
    path.dirname(currentFilePath), filename
  )

  const rPath = getFilePathRelativeToPackageRoot(filePath)
  if (!rPath) { return }

  const filePathRelativeToPackage = rPath.replace(/^spec\//, '')
  const packageDir = getPackageDir(currentFilePath)

  let absFilePath = path.join(
    packageDir, PACKAGE_DIR, filePathRelativeToPackage
  )

  if (fs.existsSync(absFilePath)) {
    openDocument(absFilePath)
    return
  }

  filename = path.basename(path.dirname(absFilePath)) + RUBY_EXT

  absFilePath = path.join(
    path.dirname(path.dirname(absFilePath)), filename
  )

  if (fs.existsSync(absFilePath)) {
    openDocument(absFilePath)
    return
  }
}

function promptCreateSpecFile(projectDir: string, currentFilePath: string, specFilePath: string) {
  const $promise = vscode.window.showQuickPick(['Yes', 'No'], {
    placeHolder: 'Spec file was not found. Do you want to create new one?'
  })

  $promise.then((selection: string | undefined) => {
    if (selection === 'Yes') {
      createSpecFile(projectDir, currentFilePath, specFilePath)
    }
  })
}

function createSpecFile(projectDir: string, currentFilePath: string, specFilePath: string) {
  const packageName = getPackageNameFromPath(currentFilePath)

  if (!packageName) { return}

  const specTemplatePath = path.join(
    projectDir, '.vscode-ree', 'templates', 'spec_template.rb'
  )

  const cb = () => {
    const variables = prepareVariables(currentFilePath)
    if (!variables) { return }

    const templateContent = fs.readFileSync(specTemplatePath, { encoding: 'utf8' })
    const rPath = getRelativePackageFilePath(currentFilePath)?.replace(RUBY_EXT, '')

    const actualTemplateContent = templateContent
      .replace(/CLASS_NAME/g, variables.className)
      .replace(/OBJECT_NAME/g, variables.objectName)
      .replace(/MODULE_NAME/g, variables.moduleName)
      .replace(/PACKAGE_NAME/g, variables.packageName)
      .replace(/RELATIVE_FILE_PATH/g, rPath)

    vscode.workspace.fs
      .createDirectory(vscode.Uri.parse(path.dirname(specFilePath)))
      .then(() => {
        fs.appendFileSync(specFilePath, actualTemplateContent)
        openDocument(specFilePath)
      })
  }

  if (!fs.existsSync(specTemplatePath)) {
    vscode.workspace.fs
      .createDirectory(vscode.Uri.parse(path.dirname(specTemplatePath)))
      .then(
        () => {
          fs.appendFileSync(
            specTemplatePath,
            SPEC_TEMPLATE
          )

          cb()
        }
      )
  } else {
    cb()
  }
}