<!--suppress NpmUsedModulesInstalled -->
<template>
    <Layout id="app">
        <Header>
            <NavBar/>
        </Header>
        <Content id="show-content">
            <router-view v-if="refreshing"></router-view>
            <BackTop :class="showBackToTop ? 'show-back-to-top' : ''" @click.native="backToTop"></BackTop>
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
                refreshing: true,
                showBackToTop: false,
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
                this.$utils.scrollbar.scrollTo(0);
                this.showBackToTop = false;
            },
            watchScroll(event) {
                this.showBackToTop = event.target.scrollTop > 100;
            }
        },
        mounted() {
            this.$utils.scrollbar.initialise("#show-content");
            this.$utils.browser.route.history.InterceptBackInit();
            document.querySelector("#show-content").addEventListener('ps-scroll-y', this.watchScroll)
        },
        beforeDestroy() {
            this.$utils.scrollbar.destroy();
            this.$utils.browser.route.history.InterceptBackDestroy();
            document.querySelector("#show-content").removeEventListener('ps-scroll-y', this.watchScroll);
        }
    }
</script>

<style scoped>
    #app {
        background: #f5f7f9;
        position: relative;
    }

    .show-back-to-top {
        display: block;
    }
</style>
