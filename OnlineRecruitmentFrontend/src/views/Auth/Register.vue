<!--suppress ALL -->
<template>
    <div class="content">
        <div class="register-background">
            <img alt="" src="~@assets/pictures/background.jpg"/>
            <div class="mask"></div>
        </div>
        <Card class="register-card">
            <h1 slot="title">登录</h1>
            <Form ref="register">
                <FormItem prop="user">
                    <Input type="text" size="large" v-model="phone" placeholder="手机号">
                        <Icon type="ios-person-outline" slot="prepend"></Icon>
                        <Button type="primary" slot="append" @click.native="sendSms" :disabled="smsTimer !== 0">
                            {{codeTips}}
                        </Button>
                    </Input>
                </FormItem>
                <FormItem prop="password">
                    <Input type="password" size="large" v-model="password" placeholder="密码">
                        <Icon type="ios-lock-outline" slot="prepend"></Icon>
                    </Input>
                </FormItem>
                <FormItem prop="password">
                    <Input type="password" size="large" v-model="password_confirm" placeholder="确认密码">
                        <Icon type="ios-lock-outline" slot="prepend"></Icon>
                    </Input>
                </FormItem>
                <FormItem prop="password">
                    <Input type="text" size="large" v-model="code" placeholder="验证码">
                        <Icon type="ios-lock-outline" slot="prepend"></Icon>
                    </Input>
                </FormItem>
                <FormItem class="register-button">
                    <Button type="success" size="large" long @click.native="register">注册</Button>
                </FormItem>
                <FormItem class="register-button-group">
                    <Button size="small" type="text" @click.native="$utils.browser.route.jump('/login')">登录</Button>
                </FormItem>
            </Form>
        </Card>
    </div>
</template>

<script>
    import Crypto from 'crypto';

    export default {
        name: "Register",
        data() {
            return {
                phone: "",
                code: "",
                password: "",
                password_confirm: "",
                codeTips: "获取验证码",
                smsTimer: 0,
            }
        },
        methods: {
            async sendSms() {
                await this.$api.verify.phoneVerify({}, {phone: this.phone});
                let timer = 60;
                this.smsTimer = setInterval(() => {
                    timer--;
                    this.codeTips = "已发送(" + timer + ")";
                    if (timer === 0) {
                        this.codeTips = "获取验证码";
                        timer = 60;
                        clearInterval(this.smsTimer);
                        this.smsTimer = 0;
                    }
                }, 1000);
            },
            async register() {
                let request = {};
                if (this.password != this.password_confirm) {
                    return this.$Message.error("密码不一致")
                }
                request.phone = this.phone;
                request.code = this.code;
                request.password = Crypto.createHash("md5").update(this.password).digest('hex');
                let response = await this.$api.auth.register({}, request).catch(error => {
                    this.$Message.error("登录失败");
                    console.log(error)
                });
                if (response) {
                    this.$Message.info("注册成功");
                    await this.$store.dispatch("auth/changeToken", response.token);
                }
                //todo jump update user info
            },
        },
    }
</script>

<style scoped>
    .content {
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .register-background {
        width: 100%;
        height: 100%;
        line-height: 100%;
        position: absolute;
        bottom: 0;
        left: 0;
        overflow: hidden;
    }

    .register-background img {
        width: 100%;
        height: 100%;
    }

    .mask {
        width: 100%;
        height: 100%;
        position: absolute;
        top: 0;
        left: 0;
        background: #000;
        filter: opacity(0.3);
    }

    .register-card {
        width: 360px;
        height: 460px;
    }

    .register-button-group {
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
    }
</style>