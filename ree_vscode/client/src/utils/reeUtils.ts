const childProcess = require('child_process')
const vscode = require('vscode')

export interface ExecCommand {
  message: string
  code: number
}

export function isReeInstalled(projectDir: string): ExecCommand | undefined {
  try {
    let spawnSync = childProcess.spawnSync
    let rootProjectDir = projectDir
    const dockerPresented = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('presented') as boolean
    const containerName = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('containerName') as string
    const appDirectory = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('appDirectory') as string
    let child = null

    if (dockerPresented) {
      rootProjectDir = appDirectory
      child = spawnSync(
        'docker', [
          'exec',
          '-i',
          '-e',
          'REE_SKIP_ENV_VARS_CHECK=true',
          '-w',
          rootProjectDir,
          containerName,
          'bundle',
          'show',
          'ree'
        ]
      )
    } else {
      child = spawnSync('which', ['ree'], {cwd: rootProjectDir })
    }

    return {
      message: child.status === 0 ? child.stdout.toString() : child.stderr.toString(),
      code: child.status
    }
  } catch(e) {
    vscode.window.errorInformationMessage(`Error. ${e}`)
    return
  }
}

export function isBundleGemsInstalled(projectDir: string): ExecCommand | undefined {
  try {
    const spawnSync = childProcess.spawnSync
    const child = spawnSync('bundle', ['show', 'ree'], {cwd: projectDir })

    return {
      message: child.status === 0 ? child.stdout.toString() : child.stderr.toString(),
      code: child.status
    }
  } catch(e) {
    vscode.window.errorInformationMessage(`Error. ${e}`)
    return
  }
}

export function isBundleGemsInstalledInDocker(): ExecCommand | undefined {
  try {
    const spawnSync = childProcess.spawnSync
    
    const dockerPresented = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('presented') as boolean
    const containerName = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('containerName') as string
    const appDirectory = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('appDirectory') as string

    if (dockerPresented) {
      const rootProjectDir = appDirectory
      const child = spawnSync(
        'docker', [
          'exec',
          '-i',
          '-e',
          'REE_SKIP_ENV_VARS_CHECK=true',
          '-w',
          rootProjectDir,
          containerName,
          'bundle',
          'show',
          'ree'
        ]
      )

      return {
        message: `Docker: ${child.status === 0 ? child.stdout.toString() : child.stderr.toString()}`,
        code: child.status
      }
    }
  } catch(e) {
    vscode.window.errorInformationMessage(`Error. ${e}`)
    return
  }
}

export function genPackageSchemaJsonCommandArgsArray(projectDir: string, name?: string) {
  if (name) { return ['gen.package_json', name.toString(), '--project_path', projectDir, '--trace'] }
  
  return  ['gen.package_json', '--project_path', projectDir, '--trace']
}

export function genObjectSchemaJsonCommandArgsArray(projectDir: string, packageName: string, objectPath: string) {
  return  ['gen.schema_json', packageName, objectPath, '--project_path', projectDir, '--trace']
}