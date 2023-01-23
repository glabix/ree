import { client } from "../extension"
import { getNewProjectIndex } from "../utils/packagesUtils"

export function reindexProject() {
  getNewProjectIndex()
  client.sendNotification("reeLanguageServer/reindex")
}