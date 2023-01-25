import { client } from "../extension"
import { getNewProjectIndex } from "../utils/packagesUtils"

export function reindexProject() {
  getNewProjectIndex(true)
  client.sendNotification("reeLanguageServer/reindex")
}