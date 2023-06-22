import { createRouter, createWebHistory } from 'vue-router'

const basePath = import.meta.env.VITE_BASE_PATH

const router = createRouter({
  history: createWebHistory(basePath || '/'),
  routes: [
    {
      path: '/',
      component: () => import('@/layouts/Default.vue'),
      children: [
        {
          path: '',
          component: () => import('@/components/Tracker/Tracker.vue'),
          name: 'app.index',
        },
        {
          path: ':month?',
          component: () => import('@/components/Tracker/Tracker.vue'),
          name: 'tracker.index',
        },
        {
          path: 'admin/users',
          component: () => import('@/components/Admin/Users.vue'),
          name: 'users.index',
        },
      ],
    }
  ]
})

export default router
