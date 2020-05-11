<!--suppress ALL -->
<template>
    <div>
        <List item-layout="vertical">
            <ListItem>
                <ListItemMeta :title="group.name" :description="mapCategory(group)"/>
                {{group.description}}
                <template slot="action">
                    <li>
                        <span v-if="$store.getters['auth/LoginState']">加入圈子</span>
                    </li>
                </template>
                <template slot="extra">
                    <div class="group-avatar">
                        <img :src="group.avatar" style="width: 128px; height: 128px; object-fit: contain;">
                    </div>
                </template>
            </ListItem>
        </List>
        <Divider>动态</Divider>
        <div style="float: right;">
            <span @click="sort = 'hottest'" style="cursor: pointer"
                  :style="{'color':sort == 'hottest' ? 'blue' : 'unset'}">最热</span>
            <Divider type="vertical"/>
            <span @click="sort = 'newest'" style="cursor: pointer"
                  :style="{'color':sort == 'newest' ? 'blue' : 'unset'}">最新</span>
        </div>
        <List item-layout="vertical" :loading="onLoading" style="margin-top: 42px">
            <ListItem v-if="!onLoading" v-for="item in posts" :key="item.id">
                <ListItemMeta :avatar="item.avatar">
                    <template slot="title">
                        <span>{{item.nickname}}</span>
                        <Icon type="ios-pin" v-if="item.is_pinned"/>
                    </template>
                </ListItemMeta>
                {{item.content}}
                <template slot="action">
                    <li>
                        <Time :time="item.timestamp" type="date"/>
                    </li>
                    <li>
                        <Icon type="ios-star-outline"/>
                        {{item.favorite_number}}
                    </li>
                    <li>
                        <Icon type="ios-thumbs-up-outline"/>
                        {{item.like_number}}
                    </li>
                    <li>
                        <Icon type="ios-chatboxes-outline"/>
                        {{item.comment_number}}
                    </li>
                </template>
            </ListItem>
        </List>
    </div>
</template>

<script>
    export default {
        inject: ['reload'],
        data() {
            return {
                group: {},
                categoryList: [],
                posts: [],
                sort: "hottest",
                page: {
                    current: 1,
                    pageSize: 10,
                    totalSize: 0,
                    list: []
                },
                onLoading: true,
            }
        },
        watch: {
            sort: function (val) {
                this.onLoading = true;
                this.fetchPost();
            }
        },
        methods: {
            async fetchPost() {
                let post = await this.$api.post.all({}, {
                    group_id: this.group.id,
                    sort_col: this.sort == 'hottest' ? 'hottest' : 'newest',
                });
                if (post) {
                    post.forEach(value => {
                        this.fetchUserProfile(value)
                    })
                    let pinned = post.filter(item => item.is_pinned);
                    let pinnedId = [];
                    for (let index = 0; index < pinned.length; index++) {
                        pinnedId[pinned[index].id] = true;
                    }
                    let left = [];
                    for (let index = 0; index < post.length; index++) {
                        if (!pinnedId[post[index].id])
                            left.push(post[index])
                    }
                    this.posts = pinned.concat(left);
                    this.$nextTick(() => {
                        this.onLoading = true;
                        setTimeout(() => {
                            this.onLoading = false;
                        }, 1000);
                    })
                } else {
                    this.posts = [];
                    this.$nextTick(() => {
                        this.onLoading = true;
                        setTimeout(() => {
                            this.onLoading = false;
                        }, 1000);
                    })
                }
            },
            async fetchUserProfile(post) {
                let profile = await this.$api.auth.userProfile({}, {
                    user_id: post.user_id,
                })
                if (profile)
                    this.$utils.tools.objectExtend(post, profile)
                else
                    this.$utils.tools.objectExtend(post, {
                        avatar: "",
                        nickname: "",
                    })
            },
            mapCategory(item) {
                let category = this.categoryList.filter(category => category.id === item.group_category_id)
                if (category.length >= 1)
                    return category[0].name
                else return "未知分类"
            },
            pageChanged(page) {
                this.page.list = this.positionList.slice((page - 1) * this.page.pageSize, page * this.page.pageSize);
                this.$utils.scrollbar.scrollTo(0);
            },
        },
        async created() {
            let param = await this.$utils.browser.route.fetchParam(this.$route.path);
            if (param == undefined || param == [])
                this.$utils.browser.route.jump('/');
            [this.group, this.categoryList] = param;
            this.fetchPost()
        },
    }
</script>

<style scoped>
    .group-avatar {
        width: 100%;
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
    }
</style>