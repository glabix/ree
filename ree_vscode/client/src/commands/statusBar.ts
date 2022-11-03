import * as vscode from "vscode"
import { getPackageNameFromPath } from "../utils/packageUtils"
import { getSpecFilePath } from "../utils/fileUtils"
import { forest } from "../utils/forest"

const path = require("path")
const fs = require("fs")
const PACKAGE_NAME_PRIORITY = 100
const SPEC_COUNT_PRIORITY = 90
const statusBarPackageItem = buildStatusBarItem(PACKAGE_NAME_PRIORITY)
const statusBarRspecItem = buildStatusBarItem(SPEC_COUNT_PRIORITY)

export const statusBarCallbacks = {
  onDidOpenTextDocument: (e: vscode.TextDocument) => {
    updateStatusBar(e.fileName)
  },
  onDidChangeActiveTextEditor: (e: vscode.TextEditor | undefined) => {
    if (e) {
      updateStatusBar(e.document.fileName)
    } else {
      setTimeout(
        () => {
          if (!vscode.window.activeTextEditor) {
            hideStatusBar()
          }
        }, 100
      )
    }
  }
}

export function updateStatusBar(filePath: string) {
  const packageName = getPackageNameFromPath(filePath)

  if (packageName) {
    statusBarPackageItem.text = `Package: ${packageName}`
  } else {
    statusBarPackageItem.text = `Package: -`
  }

  const specCount = getSpecCount(filePath)

  statusBarPackageItem.show()  
  statusBarRspecItem.show()

  if (fs.existsSync(filePath)) {
    if (specCount !== null) {
      statusBarRspecItem.text = `Spec count: ${specCount}`
    } else {
      statusBarRspecItem.text = ''
      statusBarRspecItem.hide()
    }
  }
}

export function hideStatusBar() {
  statusBarPackageItem.hide()
  statusBarRspecItem.hide()
}

function getSpecCount(filePath: string): number | null {
  const ext = path.parse(filePath).ext

  if (ext !== '.rb') {
    return null
  }

  const specFilePath = getSpecFilePath(filePath)
  if (!specFilePath) {
    return null
  }

  const filename = path.parse(filePath).name
  const specsFolder = path.join(path.dirname(specFilePath), filename)

  if (fs.existsSync(specFilePath)) {
    return 1
  }

  if (fs.existsSync(specsFolder)) {
    return fs.readdirSync(specsFolder).length
  }

  return 0
}

function buildStatusBarItem(priority: number): vscode.StatusBarItem {
  const statusBarItem = vscode.window.createStatusBarItem(
    vscode.StatusBarAlignment.Left,
    priority
  )

  return statusBarItem
}
