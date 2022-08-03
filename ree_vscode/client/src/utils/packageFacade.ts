const fs = require('fs')

let cachedPackages: ICachedGems = {}

interface ICachedGems {
  [key: string]: {
    ctime: number
    schema: any
  }
}

export interface IPackageDep {
  name: string
}

export interface IPackageEnvVar {
  name: string
  doc: string | null
}

export interface IObject {
  name: string
  schema: string
}
export interface IPackage {
  schema_type: string
  name: string
  entry_path: string
  tags: string[]
  depends_on: IPackageDep[]
  env_vars: IPackageEnvVar[],
  objects: IObject[]
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

    this.schema = this.getCachedSchema()
    return this.schema as IPackage
  }

  private getCachedSchema(): any {
    const ctime = fs.statSync(this.schemaPath).ctimeMs

    if (
      Object.keys(cachedPackages).length === 0 ||
      (cachedPackages[this.schemaPath] && cachedPackages[this.schemaPath].ctime !== ctime) ||
      (!cachedPackages[this.schemaPath])
      ) {
      const json = JSON.parse(fs.readFileSync(this.schemaPath, { encoding: 'utf8' }))
      cachedPackages[this.schemaPath.toString()] = {
        ctime: ctime,
        schema: json
      }

      return json
    } else {
      return cachedPackages[this.schemaPath].schema
    }
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
