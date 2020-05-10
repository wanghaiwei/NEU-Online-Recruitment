<!--suppress ALL -->
<template>
    <div>
        <Form ref="search" inline>
            <FormItem prop="location">
                <Select v-model="search.grade" multiple prefix="ios-book" placeholder="职位类型"
                        style="width:180px">
                    <Option v-for="item in grade" :value="item.id" :key="item.id">{{ item.label }}
                    </Option>
                </Select>
            </FormItem>
            <FormItem prop="location">
                <Select v-model="search.position_category_id" multiple prefix="ios-globe-outline"
                        placeholder="职位类型">
                    <Option v-for="item in categoryList" :value="item.id" :key="item.id">{{ item.name }}
                    </Option>
                </Select>
            </FormItem>
            <FormItem prop="location">
                <Select v-model="search.location" prefix="ios-locate-outline" placeholder="地点"
                        style="width: 120px">
                    <Option v-for="item in locationList" :value="item" :key="item">{{ item }}</Option>
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
            <ListItem v-for="item in page.list" :key="item.title">
                <ListItemMeta :title="item.name" :description="generateDes(item)" @click.native="detail(item)"
                              class="position-detail"/>
                {{ item.description.slice(0,25) }}...
                <template slot="action">
                    <li>
                        <Time :time="item.post_time" type="date"/>
                    </li>
                </template>
                <template slot="extra">
                    <div class="position-img">
                        <img :src="fetchCompanyImg(item.company)" onerror="this.src = '/company/no_nompany.png';"
                             style="width: 280px;height: 140px; object-fit: contain;">
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
                positionList: [],
                categoryList: [],
                locationList: [],
                grade: [{id: 0, label: "全职"}, {id: 1, label: "实习"}],
                search: {
                    content: "",
                    location: "",
                    position_category_id: [-1],
                    grade: [0, 1]
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
                let category = await this.$api.position.allCategory({}, {});
                if (category)
                    this.categoryList = category;
                else
                    this.categoryList = [];
            },
            async fetch() {
                let position = await this.$api.position.search({}, {
                    content: this.search.content,
                    location: this.search.location == "全部" ? "" : this.search.location,
                    position_category_id: this.search.position_category_id === [] ? [-1] : this.search.position_category_id,
                    grade: this.search.grade === [] ? [0, 1] : this.search.grade,
                });
                if (position) {
                    this.positionList = position;
                    this.locationList = ["全部", ...new Set(this.locationList.concat(this.positionList.map(item => item.location)))];
                    this.page.totalSize = this.positionList.length
                    this.page.current = 1;
                    this.page.list = this.positionList.slice(0, 1 * this.page.pageSize > this.page.totalSize ? this.page.totalSize : 1 * this.page.pageSize);
                } else
                    this.positionList = [];
            },
            fetchCompanyImg(company) {
                return `/company/${company}.png`
            },
            generateDes(item) {
                if (item == undefined)
                    return ""
                let category = this.categoryList.filter(category => category.id === item.position_category_id)
                if (category.length >= 1)
                    category = category[0].name
                else category = "未知分类"
                let grade = this.grade.filter(grade => grade.id === item.grade)
                if (grade.length >= 1)
                    grade = grade[0].label
                else grade = "未知工作时长"
                return `${item.company} | ${category} | ${item.location} | ${grade}`
            },
            pageChanged(page) {
                this.page.list = this.positionList.slice((page - 1) * this.page.pageSize, page * this.page.pageSize);
                this.$utils.scrollbar.scrollTo(0);
            },
            detail(item) {
                this.$utils.browser.route.jump("/position/detail", [
                    item,
                    this.grade,
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

    .position-img {
width: 100%;
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
    }
</style>