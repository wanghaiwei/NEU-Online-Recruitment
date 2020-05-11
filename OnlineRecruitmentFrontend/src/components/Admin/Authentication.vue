<template>
    <div>
        <h1>身份认证申请表</h1>
        <Table border :columns="columns" :data="data">
            <template slot-scope="{ row, index }" slot="company_serial">
                <Button type="primary" size="small">点击查看</Button>
            </template>
            <template slot-scope="{ row, index }" slot="begin_time">
                <Time :time="row.begin_time" type="date"/>
            </template>
            <template slot-scope="{ row, index }" slot="end_time">
                <Time :time="row.end_time" type="date"/>
            </template>
            <template slot-scope="{ row, index }" slot="action">
                <Button type="primary" size="small" style="margin-right: 5px">同意</Button>
                <Button type="error" size="small">拒绝</Button>
            </template>
        </Table>
    </div>
</template>

<script>
    export default {
        name: "Authentication",
        data() {
            return {
                columns: [{
                    title: '用户身份',
                    key: 'identity'
                }, {
                    title: '供职公司',
                    key: 'company'
                }, {
                    title: '用户职位',
                    key: 'position'
                }, {
                    title: '企业邮箱',
                    key: 'mail'
                }, {
                    title: '邮箱验证',
                    key: 'mail_can_verify'
                }, {
                    title: '工牌照片',
                    slot: 'company_serial',
                    key: 'company_serial'
                }, {
                    title: '开始时间',
                    slot: 'begin_time',
                    key: 'begin_time'
                }, {
                    title: '过期时间',
                    slot: 'end_time',
                    key: 'end_time'
                }, {
                    title: '操作',
                    slot: 'action',
                    width: 150,
                    align: 'center'
                }],
                data: [{
                    identity: "HR",
                    company: "阿里巴巴",
                    position: "前端研发",
                    mail: "user@alibaba.cn",
                    mail_can_verify: "已验证",
                    begin_time: new Date("2020-05-11"),
                    end_time: new Date("2020-07-11"),
                }]
            }
        },
    }
</script>

<style scoped>

</style>