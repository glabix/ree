const fs = require('fs')

export interface IPackageDep {
  name: string
}

export interface IPackageEnvVar {
  name: string
  doc: string | null
}

export interface IPackage {
  schema_type: string
  ree_version: string
  name: string
  entry_path: string
  tags: string[]
  depends_on: IPackageDep[]
  env_vars: IPackageEnvVar[],
  objects: IObject[]
}

interface IObject {
  name: string
  schema: string
}

export class PackageFacade {
  readonly schemaPath: string
  private schema: IPackage | null = null
  
  constructor(schemaPath: string) {
    this.schemaPath = schemaPath
    return this
  }

  private parsedSchema(): IPackage {
    if (this.schema) {
      return this.schema
    }

    this.schema = JSON.parse(fs.readFileSync(this.schemaPath, { encoding: 'utf8' }))
    return this.schema as IPackage
  }

  name(): string {
    return this.parsedSchema().name
  }

  deps(): IPackageDep[] {
    return this.parsedSchema().depends_on
  }

  objects(): IObject[] {
    return this.parsedSchema().objects as IObject[]
  }

  tags(): string[] {
    return this.parsedSchema().tags
  }

  envVars(): IPackageEnvVar[] {
    return this.parsedSchema().env_vars
  }

  entryPath(): string {
    return this.parsedSchema().entry_path
  }
}
