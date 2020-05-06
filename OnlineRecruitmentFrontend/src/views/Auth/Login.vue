<!--suppress ALL -->
<template>
    <div class="content">
        <div class="login-background">
            <img alt="" src="~@assets/pictures/background.jpg"/>
            <div class="mask"></div>
        </div>
        <Card class="login-card">
            <h1 slot="title">登录</h1>
            <Form ref="login">
                <Tabs v-model="loginType">
                    <TabPane label="密码登录" name="password">
                        <FormItem prop="user">
                            <Input type="text" size="large" v-model="phone" placeholder="手机号">
                                <Icon type="ios-person-outline" slot="prepend"></Icon>
                            </Input>
                        </FormItem>
                        <FormItem prop="password">
                            <Input type="password" size="large" v-model="password" placeholder="密码">
                                <Icon type="ios-lock-outline" slot="prepend"></Icon>
                            </Input>
                        </FormItem>
                    </TabPane>
                    <TabPane label="验证码登录" name="code">
                        <FormItem prop="user">
                            <Input type="text" size="large" v-model="phone" placeholder="手机号">
                                <Icon type="ios-person-outline" slot="prepend"></Icon>
                                <Button type="primary" slot="append" @click.native="sendSms" :disabled="smsTimer !== 0">
                                    {{codeTips}}
                                </Button>
                            </Input>
                        </FormItem>
                        <FormItem prop="code">
                            <Input type="text" size="large" v-model="code" placeholder="验证码">
                                <Icon type="ios-lock-outline" slot="prepend"></Icon>
                            </Input>
                        </FormItem>
                    </TabPane>
                </Tabs>
                <FormItem class="login-button">
                    <Button type="success" size="large" long @click.native="login">登录</Button>
                </FormItem>
                <FormItem class="login-button-group">
                    <Button size="small" type="text" @click.native="$utils.browser.route.jump('/register')">注册</Button>
                    <Button size="small" type="text" @click.native="$utils.browser.route.jump('/resetPwd')">忘记密码
                    </Button>
                </FormItem>
            </Form>
        </Card>
    </div>
</template>

<script>
    import Crypto from 'crypto';

    export default {
        name: "Login",
        data() {
            return {
                loginType: "code",
                phone: "",
                code: "",
                password: "",
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
            async login() {
                let request = {}
                request.type = this.loginType;
                request.phone = this.phone;
                request.code = this.code;
                request.password = Crypto.createHash("md5").update(this.password).digest('hex');
                let response = await this.$api.auth.login({}, request).catch(error => {
                    this.$Message.error("登录失败");
                    console.log(error)
                });
                let user_profile = {};
                if (response) {
                    user_profile.username = request.phone;
                    user_profile.state = true;
                    this.$Message.success("登录成功");
                    await this.$store.dispatch("auth/changeToken", response.token);
                    let profile = await this.$api.auth.userProfile({}, {
                        "user_id": response.user_id
                    }).catch(error => {
                        console.log(error)
                    }) || {};
                    user_profile.nickname = profile.nickname || "";
                    user_profile.avatar = profile.avatar;
                    await this.$store.dispatch("auth/changeLogin", user_profile);
                    await this.$utils.browser.route.jump('/');
                } else {
                    this.$Message.error("登录失败");
                    console.log(response.msg)
                }
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

    .login-background {
        width: 100%;
        height: 100%;
        line-height: 100%;
        position: absolute;
        bottom: 0;
        left: 0;
        overflow: hidden;
    }

    .login-background img {
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

    .login-card {
        width: 320px;
        height: 400px;
    }

    .login-button-group {
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
    }
</style>