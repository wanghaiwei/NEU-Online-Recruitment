<template>
    <div>
        <h1>发布职位</h1>
        <Form ref="login" style="margin-top: 16px">
            <FormItem prop="name">
                <Input type="text" size="large" v-model="position.name" placeholder="职位名称">
                    <Icon type="ios-code" slot="prepend"></Icon>
                </Input>
            </FormItem>
            <FormItem prop="company">
                <Input type="text" size="large" v-model="position.company" placeholder="公司名">
                    <Icon type="ios-compass" slot="prepend"></Icon>
                </Input>
            </FormItem>
            <FormItem prop="description">
                <Input type="text" size="large" v-model="position.description" placeholder="职位描述">
                    <Icon type="ios-information" slot="prepend"></Icon>
                </Input>
            </FormItem>
            <FormItem prop="post_mail">
                <Input type="text" size="large" v-model="position.post_mail" placeholder="投递邮箱">
                    <Icon type="ios-mail" slot="prepend"></Icon>
                </Input>
            </FormItem>
            <FormItem prop="location">
                <Input type="text" size="large" v-model="position.location" placeholder="Base地点">
                    <Icon type="ios-locate" slot="prepend"></Icon>
                </Input>
            </FormItem>
            <FormItem prop="grade">
                <Select size="large" v-model="position.grade" prefix="ios-book" placeholder="职位类型">
                    <Option v-for="item in grade" :value="item.id" :key="item.id">{{ item.label }}
                    </Option>
                </Select>
            </FormItem>
            <FormItem prop="position_category_id">
                <Select size="large" v-model="position.position_category_id" prefix="ios-globe-outline"
                        placeholder="职位类型">
                    <Option v-for="item in categoryList" :value="item.id" :key="item.id">{{ item.name }}
                    </Option>
                </Select>
            </FormItem>
            <FormItem class="login-button">
                <Button type="success" size="large" long @click.native="login">提交</Button>
            </FormItem>
        </Form>
    </div>
</template>

<script>
    export default {
        name: "Authentication",
        data() {
            return {
                categoryList: [],
                grade: [{id: 0, label: "全职"}, {id: 1, label: "实习"}],
                position: {
                    name: "",
                    company: "",
                    description: "",
                    post_mail: "",
                    location: "",
                    grade: "",
                    position_category_id: -1,
                },
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
        },
        async mounted() {
            await this.fetchCategory()
        }
    }
</script>

<style scoped>

</style>