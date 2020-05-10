<!--suppress ALL -->
<template>
    <div>
        <Form ref="search" inline>
            <FormItem prop="location">
                <Select v-model="search.group_category_id" multiple prefix="ios-globe-outline"
                        placeholder="圈子类型">
                    <Option v-for="item in categoryList" :value="item.id" :key="item.id">{{ item.name }}
                    </Option>
                </Select>
            </FormItem>
            <FormItem prop="content">
                <Input type="text" v-model="search.content" placeholder="搜索内容">
                    <Icon type="ios-search-outline" slot="prepend"></Icon>
                </Input>
            </FormItem>
            <FormItem>
                <Button type="primary" @click="fetch">搜索</Button>
            </FormItem>
        </Form>
        <List item-layout="vertical">
            <ListItem v-for="item in page.list" :key="item.id">
                <ListItemMeta :title="item.name" :description="mapCategory(item)" @click.native="jumpPosts(item)"
                              class="position-detail"/>
                {{item.description.slice(0,25)}}...
                <template slot="action">
                    <li>
                        <button type="text" v-if="$store.getters['auth/LoginState']">加入圈子</button>
                    </li>
                </template>
                <template slot="extra">
                    <div class="group-avatar">
                        <img :src="item.avatar" style="width: 96px; height: 96px; object-fit: scale-down;">
                    </div>
                </template>
            </ListItem>
            <div style="text-align: center" slot="footer">
                <Page :total="page.totalSize" :current.sync="page.current" show-total
                      :page-size="page.pageSize" @on-change="pageChanged"/>
            </div>
        </List>
    </div>
</template>

<script>
    export default {
        name: "Search",
        data() {
            return {
                groupList: [],
                categoryList: [],
                search: {
                    content: "",
                    group_category_id: [-1],
                },
                page: {
                    current: 1,
                    pageSize: 10,
                    totalSize: 0,
                    list: []
                }
            }
        },
        methods: {
            async fetchCategory() {
                let category = await this.$api.group.allCategory({}, {});
                if (category)
                    this.categoryList = [{id: -1, name: "全部"}, ...category];
                else
                    this.categoryList = [];
            },
            async fetch() {
                let group = await this.$api.group.allInfo();
                if (group) {
                    this.groupList = group;
                    this.page.totalSize = this.groupList.length
                    this.page.current = 1;
                    this.page.list = this.groupList.slice(0, 1 * this.page.pageSize > this.page.totalSize ? this.page.totalSize : 1 * this.page.pageSize);
                } else
                    this.groupList = [];
            },
            async searchContent() {
                let group = await this.$api.group.search({}, {
                    content: this.search.content,
                    group_category_id: this.search.group_category_id === [] ? [-1] : this.search.group_category_id,
                });
                if (group) {
                    this.groupList = group;
                    this.page.totalSize = this.groupList.length
                    this.page.current = 1;
                    this.page.list = this.groupList.slice(0, 1 * this.page.pageSize > this.page.totalSize ? this.page.totalSize : 1 * this.page.pageSize);
                } else
                    this.groupList = [];
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
            jumpPosts(item) {
                this.$utils.browser.route.jump("/group/post", [
                    item,
                    this.categoryList
                ])
            },
        },
        async created() {
            await this.fetchCategory();
            await this.fetch();
        },
    }
</script>

<style scoped>
    .position-detail {
        cursor: pointer;
    }

    .group-avatar {
width: 100%;
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
    }
</style>