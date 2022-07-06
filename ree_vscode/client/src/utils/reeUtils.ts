const childProcess = require('child_process')
const vscode = require('vscode')

export interface ExecCommand {
  message: string
  code: number
}

export function isReeInstalled(projectDir: string): ExecCommand | undefined {
  try {
    let spawnSync = childProcess.spawnSync
    let child = spawnSync('which', ['ree'], {cwd: projectDir })

    return {
      message: child.status === 0 ? child.stdout.toString() : child.stderr.toString(),
      code: child.status
    }
  } catch(e) {
    vscode.window.showInformationMessage(`Error. ${e}`)
    return
  }
}