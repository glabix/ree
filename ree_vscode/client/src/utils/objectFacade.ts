const fs = require('fs')

interface IObject {
  schema_type: string
  ree_version: string
  name: string
  path: string
  mount_as: string
  // TODO: add other fields?
}

export class ObjectFacade {
  readonly schemaPath: string
  private schema: IObject | null = null
  
  constructor(schemaPath: string) {
    this.schemaPath = schemaPath
    return this
  }

  private parsedSchema(): IObject {
    if (this.schema) {
      return this.schema
    }

    this.schema = JSON.parse(fs.readFileSync(this.schemaPath, { encoding: 'utf8' }))
    return this.schema as IObject
  }

  name(): string {
    return this.parsedSchema().name
  }

  path(): string {
    return this.parsedSchema().path
  }
}