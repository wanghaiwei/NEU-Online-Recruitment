<!--suppress ALL -->
<template>
    <div class="side">
        <div>
            <Button v-if="$store.getters['auth/LoginState']" type="info" icon="ios-add" long>创建圈子</Button>
            <Button v-else type="info" long @click="$utils.browser.route.jump('/login')">登录</Button>
        </div>
        <Divider>分割线</Divider>
        <div>
            网站信息区域，留空
        </div>
    </div>
</template>

<script>
    export default {
        name: "Sidebar"
    }
</script>

<style scoped>
    .side {
        padding: 8px 16px;
    }
</style>