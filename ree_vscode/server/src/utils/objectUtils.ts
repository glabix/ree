import { getProjectRootDir } from "./packageUtils"

const fs = require('fs')
const path = require('path')

export interface IMethodArg {
  arg: string
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

export interface IObject {
  schema_type: string
  ree_version: string
  name: string
  path: string
  mount_as: string
  class: string
  factory: string | null
  methods: IObjectMethod[]
  links: IObjectLink[]
}

export function loadObjectSchema(objectSchemaPath: string): IObject | null {
  let schema: IObject | null = null

  try {
    schema = JSON.parse(
      fs.readFileSync(objectSchemaPath, { encoding: 'utf8' })
    ) as IObject
  } catch (err) {
    console.log('failed to load Object schema', err, objectSchemaPath)
    return null
  }
  
  return schema
}