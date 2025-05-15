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
          path: ':timesheet?/:month?',
          components: {
            default: () => import('@/components/Tracker/Tracker.vue'),
            Sidebar: () => import('@/components/Tracker/Sidebar.vue'),
          },
          name: 'tracker.index',
        },
        {
          path: ':timesheet/period/:period_id/user/:user_id',
          components: {
            default: () => import('@/components/Tracker/Period.vue'),
            Sidebar: () => import('@/components/Tracker/PeriodSidebar.vue'),
          },
          name: 'tracker.period.user',
        },
        {
          path: 'admin/timesheets',
          components: {
            default: () => import('@/components/Admin/Timesheets/Index.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'timesheets.index',
        },
        {
          path: 'admin/timesheets/new',
          components: {
            default: () => import('@/components/Admin/Timesheets/Form.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'timesheets.new',
        },
        {
          path: 'admin/timesheets/:id/edit',
          components: {
            default: () => import('@/components/Admin/Timesheets/Form.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'timesheets.edit',
        },
        {
          path: 'admin/timesheets/:id/invite',
          components: {
            default: () => import('@/components/Admin/Timesheets/Invite.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'timesheets.invite',
        },
        {
          path: 'admin/timesheets/:id/users',
          components: {
            default: () => import('@/components/Admin/Timesheets/Users.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'timesheets.users',
        },
        {
          path: 'admin/timesheets/:timesheet_id/periods',
          components: {
            default: () => import('@/components/Admin/Timesheets/Periods/Index.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.index',
        },
        {
          path: 'admin/timesheets/:timesheet_id/periods/new',
          components: {
            default: () => import('@/components/Admin/Timesheets/Periods/Form.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.new',
        },
        {
          path: 'admin/timesheets/:timesheet_id/periods/:id/edit',
          components: {
            default: () => import('@/components/Admin/Timesheets/Periods/Form.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.edit',
        },
        {
          path: 'admin/timesheets/:timesheet_id/periods/:id/stats',
          components: {
            default: () => import('@/components/Admin/Timesheets/Periods/Stats.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.stats',
        },
        {
          path: 'admin/timesheets/:timesheet_id/periods/:id/credits',
          components: {
            default: () => import('@/components/Admin/Timesheets/Periods/Credits.vue'),
            Sidebar: () => import('@/components/Admin/Sidebar.vue'),
          },
          name: 'periods.credits',
        },
        {
          path: 'join/:code',
          components: {
            default: () => import('@/components/Tracker/Join.vue'),
            Sidebar: () => import('@/components/Tracker/Sidebar.vue'),
          },
          name: 'timesheets.join',
        },
      ],
    }
  ]
})

const redirectToSelectedMonth = function(store) {
  router.replace(
    {
      name: 'tracker.index',
      params: {
        timesheet: store.state.tracker.selectedTimesheet.uuid,
        month: store.state.tracker.selectedMonth,
      },
    },
  )
}

export { router, redirectToSelectedMonth }
