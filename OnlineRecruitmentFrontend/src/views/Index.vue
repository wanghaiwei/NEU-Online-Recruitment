<template>
    <layout class="index">
        <Content>
            <Row type="flex" justify="center" align="top" :gutter="24">
                <Col span="16">
                    <Card>
                        <keep-alive>
                            <router-view name="main" v-if="$route.meta.keepAlive"></router-view>
                        </keep-alive>
                        <router-view name="main" v-if="!$route.meta.keepAlive"></router-view>
                    </Card>
                </Col>
                <Col span="6" offset="2">
                    <Card>
                        <router-view name="side"></router-view>
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