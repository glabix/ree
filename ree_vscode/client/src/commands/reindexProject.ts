import { client } from "../extension"
import { getNewProjectIndex } from "../utils/packagesUtils"

export function reindexProject() {
  getNewProjectIndex(true, true)
  if (client) {
    client.sendNotification("reeLanguageServer/reindex")
  }
}