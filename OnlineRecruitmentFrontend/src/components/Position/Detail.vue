<!--suppress ALL -->
<template>
    <div>
        <List item-layout="vertical">
            <ListItem>
                <ListItemMeta :title="position.name" :description="generateDes(position)"/>
                {{ position.description }}
                <template slot="action">
                    <li>
                        <Time :time="position.post_time || new Date()" type="date"/>
                    </li>
                    <li>
                        <Icon type="ios-star-outline"/>
                        收藏
                    </li>
                    <li>
                        <span>发布邮箱：{{position.post_mail}}</span>
                    </li>
                    <li>
                        <span>删除</span>
                    </li>
                    <li>
                        <span>编辑</span>
                    </li>
                </template>
                <template slot="extra" class="position-img">
                    <img :src="fetchCompanyImg(position.company)"
                         style="width: 280px;height: 140px; object-fit: scale-down;">
                </template>
            </ListItem>
        </List>
        <Divider>你可能会喜欢:</Divider>
        <List item-layout="vertical">
            <ListItem v-for="item in recommend" :key="item.title">
                <ListItemMeta :title="item.name" :description="generateDes(item)" @click.native="detail(item)"
                              class="position-detail"/>
                {{ item.description.slice(0,25) }}...
                <template slot="action">
                    <li>
                        <Time :time="item.post_time" type="date"/>
                    </li>
                </template>
                <template slot="extra" class="position-img">
                    <img :src="fetchCompanyImg(item.company)"
                         style="width: 280px;height: 140px; object-fit: scale-down;">
                </template>
            </ListItem>
        </List>
    </div>
</template>

<script>
    export default {
        inject: ['reload'],
        name: "Detail",
        data() {
            return {
                categoryList: [],
                grade: [{id: 0, label: "全职"}, {id: 1, label: "实习"}],
                position: {},
                recommend: [],
                loadTime: 0,
            }
        },
        methods: {
            async fetchRecommend() {
                let request;
                if (this.$store.getters["auth/LoginState"])
                    request = {
                        token: this.$store.getters["auth/Token"],
                        position_id: this.position.id,
                    };
                else
                    request = {
                        position_id: this.position.id,
                    };
                let recommend = await this.$api.recommend.list({}, request);
                if (recommend) {
                    this.recommend = recommend;
                    this.recommend.sort((a, b) => b.post_time - a.post_time);
                } else
                    this.recommend = [];

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
            async detail(item) {
                await this.$api.recommend.record({}, {
                    previous: this.position.id,
                    category: this.position.position_category_id,
                    next: item.id,
                    second: (new Date().valueOf() - this.loadTime) / 1000,
                })
                this.position = item;
                this.loadTime = new Date().valueOf();
                await this.fetchRecommend();
                this.$utils.scrollbar.scrollTo(0);
            },
        },
        async mounted() {
            let param = await this.$utils.browser.route.fetchParam(this.$route.path);
            if (param == undefined || param == [])
                this.$utils.browser.route.jump('/');
            [this.position, this.grade, this.categoryList] = param;
            await this.fetchRecommend();
            this.loadTime = new Date().valueOf()
        },
    }
</script>

<style scoped>
    .position-detail {
        cursor: pointer;
    }

    .position-img {
        display: flex;
        align-items: center;
    }
</style>