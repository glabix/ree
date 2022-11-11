import * as vscode from 'vscode'
import { SyntaxNode } from 'web-tree-sitter'
import { addDocumentProblems, ReeDiagnosticCode, removeDocumentProblems } from '../utils/documentUtils'
import { forest } from '../utils/forest'
import { getLocalePath, Locale } from '../utils/packageUtils'
import { toSnakeCase } from '../utils/stringUtils'
const fs = require('fs')
const yaml = require('js-yaml')

export function checkExceptions(filePath: string): void {
  const file = fs.readFileSync(filePath, { encoding: 'utf8' })
  const uri = vscode.Uri.parse(filePath)

  let tree = forest.getTree(uri.toString())
  if (!tree) {
    tree = forest.createTree(uri.toString(), file)
  }

  const query = forest.language.query(
    `
    (throws (argument_list)* @throws_args) @throws_call
    (
      (call
        (identifier) @raise 
        (argument_list
          (call
            (constant) @const
            (identifier)
            (argument_list)*
          )
        ) @raise_args
      ) @raise_call
      (#match? @raise "^raise")
    )
    (
      (assignment (constant)@const (call (constant) (identifier) (argument_list (simple_symbol) @code (string) @locale)))
    ) @exception_build    
    `
  )

  removeDocumentProblems(uri, ReeDiagnosticCode.exceptionDiagnostic)

  let diagnostics = []

  const queryMatches = query.matches(tree.rootNode)

  let throwsConstants = []
  let raiseConstants = []
  const throwsMatches = queryMatches.find(e => {
    return !!e.captures.find(e => e.name === 'throws_call')
  })
  const raiseMatches = queryMatches.filter(e => {
    return e.captures.filter(e => e.name === 'raise_call').length > 0
  })
  const exceptionBuildMatches = queryMatches.filter(e => {
    return !!e.captures.find(e => e.name === 'exception_build')
  })

  if (throwsMatches) {
    let constantsNode = throwsMatches.captures.find(e => e.name === 'throws_args').node
    throwsConstants = constantsNode ? constantsNode.text.replace(/\(|\)/g,'').trim().split(/(?:,|\s)+/).sort() : []
  }

  if (raiseMatches) {
    raiseConstants = raiseMatches.map(
      e => {
        let constNode = e.captures.find(e => e.name === 'const')
        return constNode ? constNode.node.text : null
      }
    ).filter(e => e !== null).sort()
  }

  if (!throwsMatches && !raiseMatches) { return }

  // If there are any raise error calls, but none for throws
  if (!throwsMatches && raiseMatches.length > 0) {
    let raiseConstNodes = raiseMatches.map(m => m.captures.find(e => e.name === 'raise_call').node)

    // TODO: maybe add message with exception name for each diagnostic
    diagnostics.push(...collectDocumentDiagnostics(
      filePath,
      raiseConstNodes,
      `You raised exceptions in code, but didn't add them to throws method for contract.`
    ))

    addDocumentProblems(uri, diagnostics)
  }

  if (throwsMatches && raiseMatches.length === 0) {
    // return if throws is empty
    if (throwsConstants.length === 0) { return }

    // else, add diagnostic about unused constants in throws
    let throwsCallNode = throwsMatches.captures.find(e => e.name === 'throws_call').node
    diagnostics.push(
      ...collectDocumentDiagnostics(filePath, [throwsCallNode], `You added exceptions to throws method, but didn't used them in code.`)
    )
    addDocumentProblems(uri, diagnostics)
  }

  if (throwsMatches && raiseMatches.length > 0) {
    // find the diff between throwsConstants and raiseConstants
    // if throws > raise -> show constant in throws and show that it's unused
    // if raise > throws -> show raise line and say that we need to add it to throws
    // if raise = throws -> do nothing
    let diffThrows = throwsConstants.filter(e => !raiseConstants.includes(e))
    let diffRaise = raiseConstants.filter(e => !throwsConstants.includes(e))

    if (diffThrows.length > diffRaise.length) {
      // find constant positions
      let throwsConstNodes = throwsMatches.captures.find(c => c.name === 'throws_args').node.children.filter(n => n.text.match(RegExp(`${diffThrows.join("|")}`)))

      diagnostics.push(
        ...collectDocumentDiagnostics(filePath, throwsConstNodes, `You added exceptions to throws method, but didn't used them in code.`)
      )
      addDocumentProblems(uri, diagnostics)
    }

    if (diffRaise.length > diffThrows.length) {
      let raiseConstMatches = raiseMatches.filter(m => {
        return m.captures.find(c => c.name === 'const').node.text.match(RegExp(`${diffRaise.join("|")}`))
      })
      let raiseConstNodes = raiseConstMatches.map(c => c.captures.find(e => e.name === 'raise_call').node)
      diagnostics.push(
        ...collectDocumentDiagnostics(filePath, raiseConstNodes, "You raised exceptions in code, but didn't add them to throws method for contract.")
      )
      addDocumentProblems(uri, diagnostics)
    }
  }


  // if everything ok with usage, let's check the naming and locales
  if (exceptionBuildMatches.length > 0) {
    let wrongNamingExceptions = exceptionBuildMatches.filter(m => {
      let constCapture = m.captures.find(c => c.name === 'const')
      let codeCapture = m.captures.find(c => c.name === 'code')
      let localeCapture = m.captures.find(c => c.name === 'locale')

      let snakeConstName = toSnakeCase(constCapture.node.text).split("_").slice(0, -1).join("_")
      let codeName = codeCapture.node.text.replace(/\:/g, '')
      let localeName = localeCapture.node.text.replace(/\"|\'/g, '').split(".").slice(-1)?.[0]

      return (snakeConstName !== codeName) || (snakeConstName !== localeName) || (codeName !== localeName)
    })

    if (wrongNamingExceptions.length > 0) {
      wrongNamingExceptions.forEach(m => {
        let constCapture = m.captures.find(c => c.name === 'const')
        let codeCapture = m.captures.find(c => c.name === 'code')
        let localeCapture = m.captures.find(c => c.name === 'locale')
        let captureArr = [constCapture, codeCapture, localeCapture]

        let snakeConstName = toSnakeCase(constCapture.node.text).split("_").slice(0, -1).join("_")
        let codeName = codeCapture.node.text.replace(/\:/g, '')
        let localeName = localeCapture.node.text.replace(/\"|\'/g, '').split(".").slice(-1)?.[0]

        let nameArr = [snakeConstName, codeName, localeName]

        let uniqNames = [...new Set(nameArr)]
        uniqNames.filter(e => checkOccurrence(nameArr, e) === 1).forEach(e => {
          let node = captureArr[nameArr.indexOf(e)].node
          diagnostics.push(
            ...collectDocumentDiagnostics(
              filePath,
              [node],
              `Exception name, exception code and locale key should be named correctly. Ex.: name: InvalidIdErr = Error.build(:invalid_id, "ex.errors.invalid_id")`
            )
          )
          addDocumentProblems(uri, diagnostics)
        })
      })
    }

    // check that locales is exists
    if (exceptionBuildMatches.length === 0) { return }

    let locales = []
    exceptionBuildMatches.forEach(e => {
      locales.push(e.captures.find(c => c.name === 'locale').node.text.replace(/\"|\'/g, ''))
    })
    if (locales.length === 0) { return }

    // find locale file
    let ruLocaleFilePath = getLocalePath(filePath, Locale.ru)
    let enLocaleFilePath = getLocalePath(filePath, Locale.en)
    let ruLocaleFile = null
    let enLocaleFile = null

    try {
      ruLocaleFile = fs.readFileSync(ruLocaleFilePath, {encoding: 'utf-8'})
      enLocaleFile = fs.readFileSync(enLocaleFilePath, {encoding: 'utf-8'})
    } catch (error) {
      vscode.window.showErrorMessage(`Error: Locale file not found - ${error}`)
      return
    }

    checkLocale(ruLocaleFile, ruLocaleFilePath, Locale.ru, locales)
    checkLocale(enLocaleFile, enLocaleFilePath, Locale.en, locales)
  }
}

function collectDocumentDiagnostics(filePath: string, nodes: SyntaxNode[], message: string): vscode.Diagnostic[] {
  let diagnostics = []
  nodes.forEach(node => {
    let range = new vscode.Range(
      new vscode.Position(node.startPosition.row, node.startPosition.column),
      new vscode.Position(node.endPosition.row, node.endPosition.column),
    )
    let diagnostic = {
      severity: vscode.DiagnosticSeverity.Warning,
      message: message,
      range: range,
      code: ReeDiagnosticCode.exceptionDiagnostic,
      source: 'ree'
    } as vscode.Diagnostic

    diagnostics.push(diagnostic)
  })

  return diagnostics
}

async function checkLocale(localeFile: string, localeFilePath: string, locale: Locale, allLocales: string[]) {
  try {
    console.log('In Check Locale', locale)
    const langLocales = yaml.load(localeFile)
    let missingValues = []
    allLocales.forEach(l => {
      let value = resolveObject(`${locale}.${l}`, langLocales)
      if (!value) { missingValues.push(l) }
    })

    if (missingValues.length > 0) {
      vscode.window.showErrorMessage(
        `${locale}.yml is missing ${missingValues.join(', ')} values`,
        { modal: true } as vscode.MessageOptions,
        ...[`Add missing values to ${locale}.yml`, 'Dismiss']
      ).then(selection => {
        if (selection === 'Dismiss') { return }

        missingValues.forEach(l => {
          eval(`langLocales['${locale}']${l.split(".").map(e => `['${e}']`).join('')} = 'MISSING VALUE'`)
        })

        let data = yaml.dump(langLocales, { 'quotingType': '"', 'sortKeys': true })
        fs.writeFileSync(localeFilePath, data, { encoding: 'utf-8' })
        vscode.workspace.openTextDocument(localeFilePath).then(doc => {
          vscode.window.showTextDocument(doc)
        })
      })
    }
  } catch (error) {
    console.log('In show error', locale)
    vscode.window.showErrorMessage(`${locale}.yml locales parsing error ${localeFilePath} - ${error}`)
  }
}

function checkOccurrence(array, element) {
  let counter = 0;
  array.flat().forEach(item =>
    {
      if (item == element) {
          counter++
      }
    }
  ) 
  return counter
}

function resolveObject(path, obj, separator='.') {
  var properties = Array.isArray(path) ? path : path.split(separator)
  return properties.reduce((prev, curr) => prev?.[curr], obj)
}