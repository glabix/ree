import * as vscode from 'vscode'
import { Query, SyntaxNode } from 'web-tree-sitter'
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
    (raise) @raise_call
    (
      (assignment 
        left: (constant) @exception_constant
        right: (call) @exception_build_call
      ) 
    ) @exception_build
    `
  ) as Query
 
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
        let constNode = e.captures.find(e => e.name === 'raise_call')?.node?.children
                        ?.find(c => c.type === 'call')?.children
                        ?.find(c => c.type === 'constant')
        return constNode ? constNode.text : null
      }
    ).filter(e => e !== null).sort()
  }

  if (!throwsMatches && raiseMatches.length === 0) { return }

  // If there are any raise error calls, but none for throws
  if (!throwsMatches && raiseMatches.length > 0) {
    let raiseConstNodes = raiseMatches.map(m => m.captures.find(e => e.name === 'raise_call').node)

    diagnostics.push(...collectDocumentDiagnostics(
      filePath,
      raiseConstNodes,
      `Raised exception is not added to fn throws(...) declaration`
    ))

    addDocumentProblems(uri, diagnostics)
  }

  if (throwsMatches && raiseMatches.length === 0) {
    // return if throws is empty
    if (throwsConstants.length === 0) { return }
    // check if we use constants without raise
    let unusedThrows = []
    throwsConstants.forEach(c => {
      const isThrowsConstIsUsed = forest.language.query(
        `(
          (constant) @call
          (#match? @call "(${c})$")
        )`
      ).matches(tree.rootNode).length > 1 // more than one, because one use is in throws already

      if (isThrowsConstIsUsed) { return }

      unusedThrows.push(c)
    })

    if (unusedThrows.length > 0) {
      // throwsMatches.captures.find(e => e.name === 'throws_args').node
      // else, add diagnostic about unused constants in throws
      let throwsConstNodes = throwsMatches.captures.find(e => e.name === 'throws_args').node.children.filter(n => n.type === 'constant').filter(n => unusedThrows.includes(n.text))

      diagnostics.push(
        ...collectDocumentDiagnostics(filePath, throwsConstNodes, `Fn throws(...) declares Exception that is not raised anywhere in the code`)
      )

      addDocumentProblems(uri, diagnostics)
    }
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
      const checkIfDiffConstIsUsed = forest.language.query(
        `(
          (constant) @call
          (#match? @call "(${diffThrows.join("|")})$")
        )`
      ).matches(tree.rootNode).length > 1 // more than one, because one use is in throws already

      if (!checkIfDiffConstIsUsed) {
        diagnostics.push(
          ...collectDocumentDiagnostics(filePath, throwsConstNodes, `Fn throws(...) declares Exception that is not raised anywhere in the code`)
        )
  
        addDocumentProblems(uri, diagnostics)
      }
    }

    if (diffRaise.length > diffThrows.length) {
      let raiseConstMatches = raiseMatches.filter(m => {
        return m.captures.find(e => e.name === 'raise_call')?.node?.children
                        ?.find(c => c.type === 'call')?.children
                        ?.find(c => c.type === 'constant').text.match(RegExp(`${diffRaise.join("|")}`))
      })

      let raiseConstNodes = raiseConstMatches.map(c => c.captures.find(e => e.name === 'raise_call').node)

      diagnostics.push(
        ...collectDocumentDiagnostics(filePath, raiseConstNodes, "Raised exception is not added to fn throws(...) declaration")
      )

      addDocumentProblems(uri, diagnostics)
    }

    if (diffRaise.length === diffThrows.length && diffRaise.join('') !== diffThrows.join('')) {
      let throwsNodes = throwsMatches.captures.find(c => c.name === 'throws_args').node.children.filter(n => n.text.match(RegExp(`${diffThrows.join("|")}`)))
      diagnostics.push(
        ...collectDocumentDiagnostics(filePath, throwsNodes, "Fn throws(...) declares Exception that is not raised anywhere in the code")
      )

      let raiseConstMatches = raiseMatches.filter(m => {
        return m.captures.find(e => e.name === 'raise_call')?.node?.children
                        ?.find(c => c.type === 'call')?.children
                        ?.find(c => c.type === 'constant').text.match(RegExp(`${diffRaise.join("|")}`))
      })
      let raiseNodes = raiseConstMatches.map(c => c.captures.find(e => e.name === 'raise_call').node)
      diagnostics.push(
        ...collectDocumentDiagnostics(filePath, raiseNodes, "Raised exception is not added to fn throws(...) declaration")
      )

      addDocumentProblems(uri, diagnostics)
    }
  }


  // if everything ok with usage, let's check the naming and locales
  if (exceptionBuildMatches.length > 0) {
    const getExceptionLocaleAndCode = (m) => {
      let constCapture = m.captures.find(c => c.name === 'exception_constant')
      let callCapture = m.captures.find(c => c.name === 'exception_build_call')
      let argsCallNode = callCapture.node.children.find(e => e.type === 'argument_list')
      let codeNode = argsCallNode.children.find(c => c.type === 'simple_symbol')
      let localeNode = argsCallNode.children.find(c => c.type === 'string')
      let snakeConstName = toSnakeCase(constCapture.node.text).split("_").slice(0, -1).join("_")
      let codeName = codeNode.text.replace(/\:/g, '')
      let localeName = localeNode.text.replace(/\"|\'/g, '').split(".").slice(-1)?.[0]

      return [snakeConstName, codeName, localeName]
    }
    let wrongNamingExceptions = exceptionBuildMatches.filter(m => {
      let [constName, codeName, localeName] = getExceptionLocaleAndCode(m)

      return (constName !== codeName) || (constName !== localeName) || (codeName !== localeName)
    })

    if (wrongNamingExceptions.length > 0) {
      wrongNamingExceptions.forEach(m => {
        let constCapture = m.captures.find(c => c.name === 'exception_constant')
        let callCapture = m.captures.find(c => c.name === 'exception_build_call')
        let argsCallNode = callCapture.node.children.find(e => e.type === 'argument_list')
        let codeNode = argsCallNode.children.find(c => c.type === 'simple_symbol')
        let localeNode = argsCallNode.children.find(c => c.type === 'string')
        let nodeArr = [constCapture.node, codeNode, localeNode]
        let nameArr = getExceptionLocaleAndCode(m)
        let uniqNames = [...new Set(nameArr)]

        uniqNames.filter(e => checkOccurrence(nameArr, e) === 1).forEach(e => {
          let node = nodeArr[nameArr.indexOf(e)]
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

    exceptionBuildMatches.forEach(m => {
      let callCapture = m.captures.find(c => c.name === 'exception_build_call')
      let argsCallNode = callCapture.node.children.find(e => e.type === 'argument_list')
      let localeNode = argsCallNode.children.find(c => c.type === 'string')
      locales.push(localeNode.text.replace(/\"|\'/g, ''))
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
      severity: vscode.DiagnosticSeverity.Error,
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
    vscode.window.showErrorMessage(`${locale}.yml locales parsing error ${localeFilePath} - ${error}`)
  }
}

function checkOccurrence(array, element) {
  let counter = 0

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