<template>
  <nav class="tracker-breadcrumbs">
    <ul>
      <li v-for="(crumb, index) in crumbs" :key="index" :class="{ 'is-active': index === crumbs.length - 1 }">
        <router-link v-if="crumb.link" :to="crumb.link">{{ crumb.text }}</router-link>
        <span v-else>{{ crumb.text }}</span>
      </li>
    </ul>
  </nav>
</template>

<script>
export default {
  name: 'Breadcrumbs',
  props: {
    crumbs: {
      type: Array,
      required: true
    }
  }
}
</script>

<style lang="scss">
  .tracker-breadcrumbs {
    margin-bottom: 1rem;
    border: 1px solid var(--grey-from-bulma);
    border-radius: 5px;
    padding: 0.5rem;
    display: inline-flex;

    ul {
      list-style-type: none;
      padding: 0;
      margin: 0;
      display: flex;
    }

    li {
      margin-right: 0.5rem;
      margin-top: 0 !important;
    }

    li:after {
      content: '>';
      margin-left: 0.5rem;
    }

    li:last-child:after {
      content: '';
    }
  }
</style>
