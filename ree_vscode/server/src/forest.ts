/**
 * Forest
 */

 import { Tree } from 'web-tree-sitter'
 import { TextDocument } from 'vscode-languageserver-textdocument'
 import TreeSitterFactory from './utils/treeSitterFactory'

 const Parser = require('web-tree-sitter')
 
 export interface IForest {
   getTree(uri: string): Tree
   createTree(uri: string, content: string): Tree
   updateTree(uri: string, content: string): Tree
   deleteTree(uri: string): boolean
 }
 
 export enum ForestEventKind {
   OPEN,
   UPDATE,
   DELETE,
 }
 
 export interface ForestEvent {
   kind: ForestEventKind
   document: TextDocument
   tree?: Tree
 }
 
 class Forest implements IForest {
   public parser: typeof Parser
   private readonly trees: Map<string, Tree>
 
   constructor() {
     this.trees = new Map()
     this.parser = TreeSitterFactory.build()
   }
 
   public getTree(uri: string): Tree {
     return this.trees.get(uri)!
   }
 
   public createTree(uri: string, content: string): Tree {
     const tree: Tree = this.parser.parse(content)
     this.trees.set(uri, tree)
 
     return tree
   }
 
   // For the time being this is a full reparse for every change
   // Once we can support incremental sync we can use tree-sitter's
   // edit functionality
   public updateTree(uri: string, content: string): Tree {
     let tree: Tree = this.getTree(uri) || undefined
     if (tree !== undefined) {
       tree = this.parser.parse(content)
       this.trees.set(uri, tree)
     } else {
       tree = this.createTree(uri, content)
     }
 
     return tree
   }
 
   public deleteTree(uri: string): boolean {
     const tree = this.getTree(uri)
     if (tree !== undefined) {
       tree.delete()
     }
     return this.trees.delete(uri)
   }
 
   public release(): void {
     this.trees.forEach(tree => tree.delete())
     this.parser.delete()
   }
 }
 
 export const forest = new Forest()
