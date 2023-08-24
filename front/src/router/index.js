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
          path: ':workspace?/:month?',
          components: {
            default: () => import('@/components/Tracker/Tracker.vue'),
            Sidebar: () => import('@/components/Tracker/Sidebar.vue'),
          },
          name: 'tracker.index',
        },
        {
          path: 'admin/users',
          components: {
            default: () => import('@/components/Admin/Users/Index.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'users.index',
        },
        {
          path: 'admin/periods',
          components: {
            default: () => import('@/components/Admin/Periods/Index.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.index',
        },
        {
          path: 'admin/periods/new',
          components: {
            default: () => import('@/components/Admin/Periods/Form.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.new',
        },
        {
          path: 'admin/periods/:id/edit',
          components: {
            default: () => import('@/components/Admin/Periods/Form.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.edit',
        },
        {
          path: 'admin/periods/:id/stats',
          components: {
            default: () => import('@/components/Admin/Periods/Stats.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.stats',
        },
        {
          path: 'admin/periods/:id/credits',
          components: {
            default: () => import('@/components/Admin/Periods/Credits.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.credits',
        },
        {
          path: 'admin/workspaces',
          components: {
            default: () => import('@/components/Admin/Workspaces/Index.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'workspaces.index',
        },
        {
          path: 'admin/workspaces/new',
          components: {
            default: () => import('@/components/Admin/Workspaces/Form.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'workspaces.new',
        },
        {
          path: 'admin/workspaces/:id/edit',
          components: {
            default: () => import('@/components/Admin/Workspaces/Form.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'workspaces.edit',
        },
      ],
    }
  ]
})

const redirectToSelectedMonth = function(store) {
  router.push(
    {
      name: 'tracker.index',
      params: {
        workspace: store.state.tracker.selectedWorkspace.uuid,
        month: store.state.tracker.selectedMonth,
      },
    },
  )
}

export { router, redirectToSelectedMonth }
