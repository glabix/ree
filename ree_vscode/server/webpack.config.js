/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

//@ts-check

'use strict';

const CopyPlugin = require("copy-webpack-plugin");
const withDefaults = require('../shared.webpack.config');
const path = require('path');

const wasmPlugin = new CopyPlugin({
	patterns: [
		{ from: require.resolve('web-tree-sitter/tree-sitter.wasm'), to: path.join(__dirname, 'out') },
		{ from: require.resolve('web-tree-sitter-ruby/tree-sitter-ruby.wasm'), to: path.join(__dirname, 'out') }
	]
})

module.exports = withDefaults({
	context: path.join(__dirname),
	entry: {
		extension: './src/index.ts',
	},
	resolve: {
		symlinks: false
	},
	output: {
		filename: 'index.js',
		path: path.join(__dirname, 'out')
	},
	plugins: [
		wasmPlugin
	]
});
