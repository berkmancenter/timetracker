import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/:month?',
      component: () => import('@/components/Tracker/Tracker.vue'),
      name: 'tracker.index',
    }
  ]
})

export default router
