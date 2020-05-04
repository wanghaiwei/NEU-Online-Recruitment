<template>
    <el-container id="app">
        <component :is="navBar"/>
        <el-container class="content">
            <div id="show-content">
                <router-view/>
                <el-backtop target="#show-content"></el-backtop>
            </div>
        </el-container>
    </el-container>
</template>

<script>
    export default {
        name: "App",
        components: {
            NavBar: () => import(/* webpackChunkName: "mNavBar" */ '@components-PC/NavBar'),
            mNavBar: () => import(/* webpackChunkName: "NavBar" */ '@components-mobile/NavBar')
        },
        data() {
            return {
                navBar: this.$utils.browser.UA.isMobile ? "mNavBar" : "NavBar",
                test: false
            }
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

<style lang="scss" scoped>
    .content {
        padding: {
            top: $nav-height;
        };
        background-color: #f6f6f6;
    }
</style>
