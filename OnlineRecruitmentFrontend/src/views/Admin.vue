<template>
    <layout class="index">
        <Content>
            <Row type="flex" justify="center" align="top" :gutter="24">
                <Col span="20" offset="2">
                    <Card>
                        <keep-alive>
                            <router-view v-if="$route.meta.keepAlive"></router-view>
                        </keep-alive>
                        <router-view v-if="!$route.meta.keepAlive"></router-view>
                    </Card>
                </Col>
            </Row>
        </Content>
    </layout>
</template>

<script>
    export default {
        name: "Index"
    }
</script>

<style scoped>
    .index {
        width: 80%;
        margin: 24px auto;
    }
</style>