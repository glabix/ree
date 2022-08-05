import { Location } from 'vscode-languageserver'
import { Position } from 'vscode-languageserver-textdocument'
import { documents } from '../documentManager'
import { extractToken, findTokenInFile, findLinkedObject, findMethod } from '../utils/tokenUtils'

const url = require('node:url')
const path = require('node:path')
const fs = require('node:fs')

export default class DefinitionAnalyzer {
	public static analyze(uri: string, position: Position): Location {
    let defaultLocation : Location = {
      uri: uri,
      range: {
        start: position,
        end: position
      } 
    }

    const doc = documents.get(uri)
    if (!doc) { return defaultLocation }

    const token = extractToken(uri, position)
    if (!token) { return defaultLocation }

    const method = findMethod(documents.get(uri).getText(), token)

    if (method.position) {
      return {
        uri: uri,
        range: {
          start: method.position,
          end: method.position
        } 
      } as Location
    }

    const linkedObject = findLinkedObject(uri, token, position)

    if (linkedObject.location) {
      return {
        uri: linkedObject.location.uri,
        range: {
          start: linkedObject.location.range.start,
          end: linkedObject.location.range.end
        } 
      } as Location
    }

    // search in file
    let findInFileLocation = findTokenInFile(token, uri)
    if (!findInFileLocation) { return defaultLocation }

    return findInFileLocation
	}
}