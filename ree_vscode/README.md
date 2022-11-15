# ree README

## Features

1. Ree: Go To Package. Easily navigate between ree packages
2. Ree: Go To Spec. Create missing spec files for package ruby files. Navigate between package files and corresponding Rspec files.
3. Ree: Generate Package Schema (Package.schema.json). Automaticaly updates package schema on package files update.
4. Ree: Generate Packages Schema (Packages.schema.json).
5. Ree: Generate Package. Create new ree package for your project.
6. Ree: Go To Package Object. Find and navigate to specific package object.
7. Go to definition for Ree objects. Navigate to Ree object source code file.
8. Hover analyser for Ree objects. Get Ree object description on hover.
9. Autocompletion for Ree objects. Start typing object name and use autocomplete to populate object links section.
10. Validation of Ree object on save. Displays issues in the problems section.

## Requirements

This extension requires `ree` binary that could be installed using rubygems: `gem install ree`.

## Release Notes

Initial release

### 0.0.1

Initial release of Ree extension

### 0.0.5
* Fixed invalid spec count in status bar
* Extended spec template to support more variables: CLASS_NAME, OBJECT_NAME, MODULE_NAME, PACKAGE_NAME, RELATIVE_FILE_PATH
* Fixed issues with spec files creation

### 0.0.6
* Ree: Go To Package Object command
* Go to definition for Ree objects
* Hover analyser for Ree objects
* Autocompletion for Ree objects

### 0.0.7
* Resolve issue with document templates not working for empty files
* Disable autocompletion for not saved files

### 0.0.9
* Docker integration. Added plugin settings to configure docker container name & app folder. Plugin will execute Ree commands inside docker container if enabled
* Code navigation, autocompletion & hints are now supported for gem packages

### 0.0.10
* Added hints for method args
* Added Go to definition support for linked constants

### 0.0.15
* Integration with ree_errors: automatic locales creation, locale names check, check if errors are added to throws etc