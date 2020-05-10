<!--suppress ALL -->
<template>
    <div>
        <h1>身份认证</h1>
        <Form ref="login" style="margin-top: 16px">
            <FormItem prop="identity">
                <Input type="text" size="large" v-model="auth.identity" placeholder="用户身份">
                    <Icon type="ios-code" slot="prepend"></Icon>
                </Input>
            </FormItem>
            <FormItem prop="company">
                <Input type="text" size="large" v-model="auth.company" placeholder="供职公司">
                    <Icon type="ios-compass" slot="prepend"></Icon>
                </Input>
            </FormItem>
            <FormItem prop="position">
                <Input type="text" size="large" v-model="auth.position" placeholder="用户职位">
                    <Icon type="ios-information" slot="prepend"></Icon>
                </Input>
            </FormItem>
            <FormItem prop="mail">
                <Input type="text" size="large" v-model="auth.mail" placeholder="企业邮箱">
                    <Icon type="ios-mail" slot="prepend"></Icon>
                    <Button type="primary" slot="append" @click.native="sendSms" :disabled="smsTimer !== 0">
                        {{codeTips}}
                    </Button>
                </Input>
            </FormItem>
            <FormItem prop="mail_can_verify" label="">
                <span>无法验证？</span>
                <iSwitch v-model="auth.mail_can_verify" size="large">
                    <span slot="open">On</span>
                    <span slot="close">Off</span>
                </iSwitch>
            </FormItem>
            <FormItem prop="code" v-if="!auth.mail_can_verify">
                <Input type="text" size="large" v-model="auth.code" placeholder="验证码">
                    <Icon type="ios-locate" slot="prepend"></Icon>
                </Input>
            </FormItem>
            <FormItem prop="company_serial">
                <Upload action="//api/uplaod/new" @on-success="uploadSuccess">
                    <Button icon="ios-cloud-upload-outline">上传工牌</Button>
                </Upload>
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
                auth: {
                    identity: "",
                    company: "",
                    position: "",
                    mail: "",
                    code: "",
                    company_serial: "",
                    mail_can_verify: false,
                },
                codeTips: "获取验证码",
                smsTimer: 0,
            }
        },
        methods: {
            uploadSuccess(response, file, fileList) {
                if (filepath in response)
                    this.auth.company_serial = response.filepath[0]
            }
        },
    }
</script>

<style scoped>

</style>