<template>
    <div>
        <h1>创建圈子</h1>
        <Form ref="login" style="margin-top: 16px" :label-width="80">
            <FormItem prop="name" label="圈子名称">
                <Input type="text" v-model="group.name" placeholder="圈子名称">
                    <Icon type="ios-code" slot="prepend"></Icon>
                </Input>
            </FormItem>
            <FormItem prop="description" label="圈子描述">
                <Input type="textarea" v-model="group.group_description" placeholder="圈子描述">
                    <Icon type="ios-information" slot="prepend"></Icon>
                </Input>
            </FormItem>
            <FormItem prop="logo" label="圈子图标">
                <Upload type="drag" :before-upload="disableAutoUpload" action="/api/upload/new">
                    <div style="padding: 20px 0">
                        <Icon type="ios-cloud-upload" size="52" style="color: #3399ff"></Icon>
                        <p>上传圈子图标</p>
                    </div>
                </Upload>
            </FormItem>
            <FormItem prop="group_category_id" label="圈子类型">
                <Select v-model="group.group_category_id" prefix="ios-globe-outline"
                        placeholder="圈子类型">
                    <Option v-for="item in categoryList" :value="item.id" :key="item.id">{{ item.name }}
                    </Option>
                </Select>
            </FormItem>
            <FormItem>
                <Button type="success" size="large" long @click.native="submit">提交</Button>
            </FormItem>
        </Form>
    </div>
</template>

<script>
    export default {
        name: "Create",
        data() {
            return {
                categoryList: [],
                group: {
                    name: "",
                    group_description: "",
                    group_category_id: 0,
                    group_avatar: null,
                },
                file: null,
            }
        },
        methods: {
            async fetchCategory() {
                let category = await this.$api.group.allCategory({}, {});
                if (category)
                    this.categoryList = category;
                else
                    this.categoryList = [];
            },
            disableAutoUpload(file) {
                this.file = file;
                return false;
            },
            submit () {

            }
        },
        async mounted() {
            await this.fetchCategory();
        },
    }
</script>

<style scoped>

</style>