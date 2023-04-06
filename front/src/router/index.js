import { createRouter, createWebHistory } from 'vue-router'

const basePath = import.meta.env.VITE_BASE_PATH

const router = createRouter({
  history: createWebHistory(basePath || '/'),
  routes: [
    {
      path: '/:month?',
      component: () => import('@/components/Tracker/Tracker.vue'),
      name: 'tracker.index',
    }
  ]
})

export default router
