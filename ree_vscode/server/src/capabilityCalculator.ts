/**
 * CapabilityCalculator
 */

import {
	ClientCapabilities,
	ServerCapabilities,
	TextDocumentSyncKind,
} from 'vscode-languageserver'

export class CapabilityCalculator {
	public clientCapabilities: ClientCapabilities
	public capabilities: ServerCapabilities

	constructor(clientCapabilities: ClientCapabilities) {
		this.clientCapabilities = clientCapabilities
		this.capabilities = {}
		this.calculateCapabilities()
	}

	get supportsWorkspaceFolders(): boolean {
		return (
			!!this.clientCapabilities.workspace && !!this.clientCapabilities.workspace.workspaceFolders
		)
	}

	get supportsWorkspaceConfiguration(): boolean {
		return !!this.clientCapabilities.workspace && !!this.clientCapabilities.workspace.configuration
	}

	private calculateCapabilities(): void {
		this.capabilities = {
			// Perform incremental syncs
			// Incremental sync is disabled for now due to not being able to get the
			// old text
			// textDocumentSync: TextDocumentSyncKind.Incremental,
			textDocumentSync: TextDocumentSyncKind.Full,
			definitionProvider: true,
			hoverProvider: true,
			completionProvider: {
				resolveProvider: true
			}
		}

		if (this.clientCapabilities.workspace && this.clientCapabilities.workspace.workspaceFolders) {
			this.capabilities.workspace = {
				workspaceFolders: {
					supported: true,
					changeNotifications: true,
				},
			}
		}
	}
}
