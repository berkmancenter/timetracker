<template>
  <div>
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Popular</h5>

    <div class="switmenu-section-content mb-2">
      <popular-items title="Projects" type="project" :items="$store.state.tracker.popular.projects"></popular-items>
    </div>

    <div class="switmenu-section-content">
      <popular-items title="Categories" type="category" :items="$store.state.tracker.popular.categories"></popular-items>
    </div>
  </div>
</template>

<script>
  import PopularItems from './PopularItems.vue'

  export default {
    name: 'Popular',
    components: {
      PopularItems,
    },
  }
</script>
