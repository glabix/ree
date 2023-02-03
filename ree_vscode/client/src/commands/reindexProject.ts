import { client } from "../extension"
import { getNewProjectIndex } from "../utils/packagesUtils"

export function reindexProject() {
  getNewProjectIndex(true, true)
  client.sendNotification("reeLanguageServer/reindex")
}