import { createRouter, createWebHashHistory } from 'vue-router'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    {
      path: '/:month?',
      component: () => import('@/components/Tracker/Tracker.vue'),
      name: 'tracker.index',
    }
  ]
})

export default router
