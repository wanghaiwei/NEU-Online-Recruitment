<!--suppress NpmUsedModulesInstalled -->
<template>
    <Layout id="app">
        <Header>
            <NavBar/>
        </Header>
        <Content id="show-content">
            <router-view/>
        </Content>
    </Layout>
</template>

<script>
    export default {
        name: "App",
        components: {
            NavBar: () => import(/* webpackChunkName: "NavBar" */ './components/NavBar'),
        },
        data() {
            return {}
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
    #app{
        background: #f5f7f9;
        position: relative;
    }
</style>
