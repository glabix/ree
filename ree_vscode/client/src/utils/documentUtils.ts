
import * as vscode from 'vscode'

export function openDocument(path: string) {
  vscode.workspace.openTextDocument(path).then((doc) => {
    vscode.window.showTextDocument(doc)
  })
}