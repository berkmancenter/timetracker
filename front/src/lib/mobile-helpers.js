export function isMobile() {
  return ('ontouchstart' in window || navigator.maxTouchPoints) && (window.innerWidth <= 700)
}
