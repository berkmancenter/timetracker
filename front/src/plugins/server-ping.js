import store from '@/store/index'
import { frontVersion } from '@/lib/app-settings'

const apiUrl = import.meta.env.VITE_API_URL
const interval = 60000
// Sooner while the server can't be reached, so the notice about it goes away
// soon after the server is back
const retryInterval = 10000
// A server which doesn't answer (e.g. a proxy waits for a stopped app) is as
// unreachable as one which refuses, the browser alone would wait for minutes
const timeout = 10000

let timer = null
let running = null

const check = async () => {
  let response
  try {
    // A redirect goes to a sign in page, e.g. of an auth proxy in front of the
    // app. It isn't followed: the browser blocks a redirect to another domain
    // and then it would look like the server is down.
    response = await fetch(`${apiUrl}/ping`, {
      credentials: 'include',
      cache: 'no-store',
      redirect: 'manual',
      headers: { 'Accept': 'application/json' },
      signal: AbortSignal.timeout(timeout),
    })
  } catch {
    return 'unreachable'
  }

  if (response.status === 401 || response.type === 'opaqueredirect') return 'signed-out'
  if (!response.ok) return 'unreachable'

  const { version } = await response.json().catch(() => ({}))
  const pageVersion = frontVersion()
  if (version && pageVersion && version !== pageVersion) store.commit('shared/setNewVersion')

  return 'ok'
}

// Asks the server if the user is still signed in and if a new version was
// deployed, resolves to 'ok', 'signed-out' or 'unreachable'. When the user is
// signed out the page is reloaded, so the server sends them to sign in.
const pingServer = () => {
  running ||= check().then((result) => {
    running = null
    store.commit('shared/setServerReachable', result !== 'unreachable')
    if (result === 'signed-out') window.location.reload()

    return result
  })

  return running
}

const pingLater = (delay) => {
  clearTimeout(timer)
  timer = setTimeout(pingNow, delay)
}

const pingNow = async () => {
  const result = await pingServer()
  if (result !== 'signed-out') pingLater(result === 'unreachable' ? retryInterval : interval)
}

// The browser knows it first when the network is gone or back
window.addEventListener('offline', () => store.commit('shared/setServerReachable', false))
window.addEventListener('online', pingNow)

pingLater(interval)

export { pingServer }
