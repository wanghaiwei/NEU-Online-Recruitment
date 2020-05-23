<!--suppress ALL -->
<template>
    <div>
        <List item-layout="vertical" :split="false" size="small">
            <ListItem v-for="item in replies" :key="item.id" class="reply">
                <span style="color: #2d9aff; cursor: pointer;">
                    <Avatar size="small" :src="item.avatar"></Avatar>
                    {{item.nickname}}&nbsp;</span>
                <span v-if="item.to_nickname">回复&nbsp;
                <span style="color: #2d9aff; cursor: pointer;">
                    <Avatar size="small" :src="item.to_avatar"></Avatar>
                    {{item.to_nickname}}：</span>
                </span>
                {{item.content}}
                <template slot="action">
                    <li>
                        <Icon type="ios-calendar-outline"/>&nbsp;
                        <Time type="date" :time="item.timestamp"></Time>
                    </li>
                    <li>
                        <span @click="">
                            <Icon type="ios-chatbubbles-outline"/> 回复
                        </span>
                    </li>
                </template>
            </ListItem>
        </List>
    </div>
</template>

<script>
    export default {
        name: "Reply",
        props: {
            replies: Array
        },
        data() {
            return {}
        },
    }
</script>

<style scoped>

</style>