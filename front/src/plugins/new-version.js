import store2 from 'store2'
import { router } from '@/router/index'
import store from '@/store/index'
import { pingServer } from '@/plugins/server-ping'

// After a deploy the files of the old front-end are gone from the server, the
// page has to be loaded again to get the new ones. This loads it when it's
// safe to do and when a lazy loaded page can't be opened.

const loadedAtKey = 'timetracker.new_version_loaded_at'
const loadPause = 10000

// Loads the page with this path from the server. Not again soon after the last
// time, a broken deploy would load the page forever.
const loadPage = (fullPath) => {
  const loadedAt = store2.session.get(loadedAtKey)
  if (loadedAt && Date.now() - loadedAt < loadPause) return false

  store2.session.set(loadedAtKey, Date.now())
  window.location.assign(router.resolve(fullPath).href)

  return true
}

// Once a new version is deployed, the next page the user opens is loaded from
// the server, not changed in place by the router. So nothing typed on the page
// they are looking at gets lost.
router.beforeEach((to) => {
  if (store.state.shared.server.newVersion && loadPage(to.fullPath)) return false
})

// Vite fires vite:preloadError when it can't load the files of a lazy loaded
// page, then the router gets the same error
const failedLoads = new WeakSet()
window.addEventListener('vite:preloadError', (event) => {
  if (event.payload instanceof Object) failedLoads.add(event.payload)
})

router.onError(async (error, to) => {
  // Without the server the page wouldn't load either. Then the user stays on
  // this page, the notice says the server can't be reached and the link works
  // when it's back.
  if (failedLoads.has(error) && await pingServer() === 'ok' && loadPage(to.fullPath)) return

  // What the router does when nothing listens for its errors
  console.error(error)
})
