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
          components: {
            default: () => import('@/components/Tracker/Tracker.vue'),
            Sidebar: () => import('@/components/Tracker/Sidebar.vue'),
          },
          name: 'tracker.index',
        },
        {
          path: 'admin/users',
          component: () => import('@/components/Admin/Users/Index.vue'),
          name: 'users.index',
        },
        {
          path: 'admin/periods',
          component: () => import('@/components/Admin/Periods/Index.vue'),
          name: 'periods.index',
        },
        {
          path: 'admin/periods/new',
          component: () => import('@/components/Admin/Periods/Form.vue'),
          name: 'periods.new',
        },
        {
          path: 'admin/periods/:id/edit',
          component: () => import('@/components/Admin/Periods/Form.vue'),
          name: 'periods.edit',
        },
        {
          path: 'admin/periods/:id/stats',
          component: () => import('@/components/Admin/Periods/Stats.vue'),
          name: 'periods.stats',
        },
        {
          path: 'admin/periods/:id/credits',
          component: () => import('@/components/Admin/Periods/Credits.vue'),
          name: 'periods.credits',
        },
      ],
    }
  ]
})

export default router
