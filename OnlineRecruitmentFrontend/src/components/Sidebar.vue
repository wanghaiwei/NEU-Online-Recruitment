<template>
    <div class="side">
        <div>
            <Button v-if="$store.getters['auth/LoginState']" type="info" icon="ios-add" long>发布</Button>
            <Button v-else type="info" icon="ios-add" long>发布</Button>
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