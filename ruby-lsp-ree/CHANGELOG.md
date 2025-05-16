## [0.1.20] - 2025-05-15

- formatter: add missing columns to entities
- add missing imports: add missing imports from string interpolation and blocks
- add missing imports: add imports in dtos
- Go To Definition: fixed for entities inside dao

## [0.1.18] - 2025-05-05

- formatter: do not remove links from mappers
- formatter: change incorrect package for link on save
- add missing imports: add more cases with missing imports

## [0.1.17] - 2025-04-28

- add missing imports: improved handling imports with the same name
- add missing imports: handle more cases with missing imports (nested calls, predicates, etc.)

## [0.1.16] - 2025-04-24

- formatter: add missing imports

## [0.1.15] - 2025-04-18

- autocomplete - don't overwrite existing arguments
- unused links formatter - handle const aliases

## [0.1.14] - 2025-04-15

- do not create error definition for defined class
- added formatter config settings
- formatter: remove unused imports
- fixed adding `throws` section to contract without parentheses

## [0.1.13] - 2025-04-04

- Go To Definition for action and serializers in routes
- support for `schema` objects
- better support for both ree locale conventions

## [0.1.11] - 2025-03-28

- fixed formatting errors for methods with `rescue`
- fixed imports from enums
- improved Add Link for constants

## [0.1.10] - 2025-03-26

- async_bean support
- rename for 'copy' files
- add diagnostics for missing locale
- link in error locale hover leads to the correct line
- missing locale notification

## [0.1.8] - 2025-03-21

- hover: show missing locales
- formatter: add raised error definition if missing
- formatter: add placeholder for missing locale
- formatter: improved adding raised errors into contract throw section
- Go To Definition: improved location for error locales
- Go To Definition: got to missing locale placeholder

## [0.1.7] - 2025-03-14

- Go To Definition for ree errors into locales
- hover for ree error locales
- formatter: add raised ree errors to `throws` section

## [0.1.6] - 2025-03-04

- file rename triggers class name change
- add documentation string to hover
- add hover on link section beans

## [0.1.5] - 2025-02-28

- improved hover format
- basic support for ree templates

## [0.1.4] - 2025-02-25

- autocompletion in spec files
- Add Link in spec files
- improved support of new files and unsaved documents

## [0.1.3] - 2025-02-21

- improved Go To Definition for ree object methods and imported constants
- support for :mapper objects
- support for :aggregate objects
- improved autocompletion for imported constants
- basic hover information for ree objects

## [0.1.2] - 2025-02-14

- support for :bean objects
- Go To Definition for imported constants
- use current (not saved) version of the document in autocomplete
- use current (not saved) version of the document in definition
- increase autocomplete list limits (affects short functions)
- improved const autocomplete
- improved ree errors handling

## [0.1.1] - 2025-02-10

- sort links for objects with FnDSL
- autocomplete for objects with FnDSL
- Add Link for objects with FnDSL
- improve params in autocomplete
- Go To Definition for symbols in link section
- autocomplete for enums
- autocomplete for enum values
- Add Link for enums
- Go To Definition for enums
- autocomplete for ree actions
- Add Link for ree actions
- sort links in ree actions
- autocomplete for ree dao
- autocomplete for dao filters

## [0.1.0] - 2025-01-31

- Initial release

## [Unreleased]
