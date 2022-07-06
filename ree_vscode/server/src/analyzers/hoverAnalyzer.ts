import { MarkupKind } from 'vscode-languageserver'
import { Position } from 'vscode-languageserver-textdocument'
import { documents } from '../documentManager'
import { Hover } from 'vscode-languageserver'
import { extractToken, findMethod, findLinkedObject, splitArgsType } from '../utils/tokenUtils'

export default class HoverAnalyzer {
	public static analyze(uri: string, position: Position): Hover {
    let defaultHover : Hover = {
      contents: {
        kind: MarkupKind.Markdown,
        value: ''
      },
      range: {
        start: position,
        end: position
      } 
    }

    let token = extractToken(uri, position)
    if (!token) { return defaultHover }

    const localMethod = findMethod(documents.get(uri).getText(), token)

    if (localMethod.position) {
      return {
        contents: {
          kind: MarkupKind.Markdown,
          value: "```ruby\n" + "\n" + localMethod.methodDef + "\n\n```"
        },
        range: {
          start: position,
          end: position
        } 
      } as Hover
    }

    const linkedObject = findLinkedObject(uri, token)
    
    if (linkedObject.linkDef) {
      let hover = ""
      
      hover = hover +"```ruby\n" + linkedObject.linkDef + "\n```"

      if (linkedObject.method) {
        let args: string[] = []


        linkedObject.method.args.forEach((a) => {
          args.push(`\n  ${a.arg}: ${splitArgsType(a.type)}`)
        })

        let methodDef = `${token}(${args.join(", ")}\n) => ${linkedObject.method.return}`

        hover = hover + "\n>---\n\n```ruby\n" + methodDef + "\n```"

        // linkedObject.method.args.forEach((a) => {
        //   hover = hover + `@param [${a.type}] ${a.arg}\n\n`
        // })

        // hover = hover + `@return [${linkedObject.method.return}]`

        // if (linkedObject.method.throws.length) {
        //   hover = hover + `\n@throws [${linkedObject.method.throws.join(", ")}]`
        // }
      }
      
      if (linkedObject.method?.doc) {
        hover = hover + "\n>---\n\n```ruby\n"
        const doc = linkedObject.method.doc.split("\n").map((s) => "# " + s).join("\n")
        hover = hover + doc + "\n```"
      }

      return {
        contents: {
          kind: MarkupKind.Markdown,
          value: hover
        },
        range: {
          start: position,
          end: position
        } 
      } as Hover
    }

    return defaultHover
  }
}

