// Settings the server adds to the page (FrontController), so one front-end
// build works for every deployment. The VITE_ values are only used when the
// page doesn't come from Rails, e.g. on the Vite dev server.
const metaContent = (name) => document.querySelector(`meta[name="${name}"]`)?.content

const authType = () => metaContent('timetracker-auth-type') || import.meta.env.VITE_AUTH_TYPE

// Version of the front-end in this page, the server's one (/ping) differs
// after a deploy. Not set on the Vite dev server.
const frontVersion = () => metaContent('timetracker-version')

export { authType, frontVersion }
