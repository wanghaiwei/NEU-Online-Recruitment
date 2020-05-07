<!--suppress NpmUsedModulesInstalled -->
<template>
    <Layout id="app">
        <Header>
            <NavBar/>
        </Header>
        <Content id="show-content">
            <router-view v-if="refreshing"></router-view>
            <BackTop @click="backToTop"></BackTop>
        </Content>
    </Layout>
</template>

<script>
    export default {
        name: "App",
        provide() {
            return {
                reload: this.refresh
            }
        },
        components: {
            NavBar: () => import(/* webpackChunkName: "NavBar" */ './components/NavBar'),
        },
        data() {
            return {
                refreshing: true
            }
        },
        methods: {
            refresh() {
                this.refreshing = false;
                this.$nextTick(() => {
                    this.refreshing = true;
                })
            },
            backToTop() {
                this.$utils.scrollbar.scrollTo(0)
            },
        },
        mounted() {
            this.$utils.scrollbar.initialise("#show-content");
            this.$utils.browser.route.history.InterceptBackInit();
        },
        beforeDestroy() {
            this.$utils.scrollbar.destroy();
            this.$utils.browser.route.history.InterceptBackDestroy();
        }
    }
</script>

<style scoped>
    #app {
        background: #f5f7f9;
        position: relative;
    }
</style>
