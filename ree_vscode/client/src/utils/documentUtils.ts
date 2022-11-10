
import * as vscode from 'vscode'
import { diagnosticCollection } from '../extension'

export enum ReeDiagnosticCode {
  exceptionDiagnostic = 0,
  reeDiagnostic = 1
}

export function openDocument(path: string) {
  vscode.workspace.openTextDocument(path).then((doc) => {
    vscode.window.showTextDocument(doc)
  })
}

export function clearDocumentProblems(uri: vscode.Uri) {
  diagnosticCollection.delete(uri)
}

export function removeDocumentProblems(uri: vscode.Uri, code: ReeDiagnosticCode) {
  let diagnostics = diagnosticCollection.get(uri)
  if (diagnostics.length === 0) { return }

  diagnosticCollection.set(uri, diagnostics.filter(d => d.code !== code))
}

export function addDocumentProblems(uri: vscode.Uri, problems: vscode.Diagnostic[]) {
  let diagnostics = [...diagnosticCollection.get(uri)]
  diagnostics.push(...problems)

  diagnosticCollection.set(uri, diagnostics)
}