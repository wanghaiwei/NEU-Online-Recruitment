<!--suppress ALL -->
<template>
    <div>
        <h1>动态详情</h1>
        <List item-layout="vertical">
            <ListItem>
                <ListItemMeta :avatar="post.avatar">
                    <template slot="title">
                        <span>{{post.nickname}}</span>
                        <Icon type="ios-pin" v-if="post.is_pinned"/>
                    </template>
                </ListItemMeta>
                {{post.content}}
                <template slot="action">
                    <li>
                        <Time :time="post.timestamp" type="date"/>
                    </li>
                    <li>
                        <Icon type="ios-star-outline"/>
                        {{post.favorite_number}}
                    </li>
                    <li>
                        <Icon type="ios-thumbs-up-outline"/>
                        {{post.like_number}}
                    </li>
                    <li>
                        <Icon type="ios-chatboxes-outline"/>
                        {{post.comment_number}}
                    </li>
                    <li>
                        <span @click="showReply = true"><Icon type="ios-chatbubbles-outline"/>回复</span>
                    </li>
                </template>
            </ListItem>
        </List>
        <Divider/>
        <List item-layout="vertical" size="small" :split="false">
            <ListItem v-for="item in commentList" :key="item.id">
                <ListItem>
                    <Avatar size="small" :src="item.avatar"></Avatar>&nbsp;&nbsp;
                    <span style="color: #2d9aff">{{item.nickname}}</span>
                    <li style="margin-left: 2.5%">{{item.content}}</li>
                    <template slot="action">
                        <li>
                            <Icon type="ios-calendar-outline"/>&nbsp;
                            <Time type="date" :time="item.timestamp"></Time>
                        </li>
                        <li>
                            <span><Icon type="ios-chatbubbles-outline"/>回复</span>
                        </li>
                    </template>
                </ListItem>
                <div v-if="item.replies" class="reply">
                    <reply :replies="item.replies"></reply>
                </div>
                <Divider/>
            </ListItem>
            <ListItem v-if="showReply">
                <div>
                    <Input v-model="inputComment" type="textarea" :rows="2" :placeholder="placeholders"></Input>
                    <div style="text-align: right;margin-top: 10px">
                        <Button style="margin-right: 10px">取消</Button>
                        <Button type="primary" round>确定</Button>
                    </div>
                </div>
            </ListItem>
        </List>
    </div>
</template>

<script>
    export default {
        name: "Comment",
        components: {
            reply: () => import(/* webpackChunkName: "Reply" */ '../../components/Post/Reply.vue'),
        },
        data() {
            return {
                post: {
                    id: 6,
                    content: "刚刚被腾讯音乐电话面试了，前面说了半天挺好的，然后问了一个股票买卖问题，给他描述了dp解法之后，居然问我是不是在网上搜索的。\n",
                    user_id: 21,
                    like_number: 21,
                    comment_number: 23,
                    favorite_number: 18,
                    timestamp: 1588262400000,
                    avatar: "/api/upload/avatar/2020/4/21.jpg",
                    nickname: "墨笙",
                    description: "没有说明"
                },
                showReply: false,
                inputComment: '',
                placeholders: '写下你的评论',
                commentList: [{
                    id: 1,
                    nickname: "张三",
                    content: "测试评论",
                    avatar: "/api/upload/avatar/2020/4/21.jpg",
                    timestamp: new Date(2020, 5, 12, 13, 56),
                    replies: [{
                        id: 2,
                        nickname: "李四",
                        to_nickname: "",
                        content: "你好",
                        avatar: "/api/upload/avatar/2020/4/21.jpg",
                        timestamp: new Date(2020, 5, 12, 14, 4),
                    }, {
                        id: 2,
                        nickname: "张三",
                        to_nickname: "李四",
                        content: "你好呀",
                        avatar: "/api/upload/avatar/2020/4/21.jpg",
                        to_avatar: "/api/upload/avatar/2020/4/21.jpg",
                        timestamp: new Date(2020, 5, 12, 14, 36),
                    }]
                },],
            }
        },
        methods: {
            async commitComment() {
                if (!this.$store.getters["auth/LoginState"]) {
                    this.$Message.warning({
                        background: true,
                        content: '发表评论请先登录！',
                    });
                    scrollTo(0, 0);
                } else {
                    if (!this.inputComment) {
                        this.$Message.warning({
                            background: true,
                            content: '评论信息不能为空！',
                        });
                    } else {
                        const comment = {
                            content: this.inputComment,
                        };
                        const {data: result} = await this.$http.post("saveComment", comment);
                        if (result.code === 200) {
                            this.$Message.success(result.message)
                        }
                    }
                }
                this.inputComment = '';
            },
            showCommentInput(item, reply) {
                if (reply) {
                    this.placeholders = "@" + reply.nickname + " "
                } else {
                    this.inputComment = ''
                }
            },
        }
    }
</script>

<style scoped>
    .reply {
        margin-left: 3em;
    }
</style>