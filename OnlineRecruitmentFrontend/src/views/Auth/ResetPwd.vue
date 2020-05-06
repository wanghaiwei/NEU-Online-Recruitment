<!--suppress ALL -->
<template>
    <div class="content">
        <div class="reset-background">
            <img alt="" src="~@assets/pictures/background.jpg"/>
            <div class="mask"></div>
        </div>
        <Card class="reset-card">
            <h1 slot="title">登录</h1>
            <Form ref="reset">
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
                <FormItem prop="password-confirm">
                    <Input type="password" size="large" v-model="password" placeholder="新密码">
                        <Icon type="ios-lock-outline" slot="prepend"></Icon>
                    </Input>
                </FormItem>
                <FormItem class="reset-button">
                    <Button type="success" size="large" long @click.native="reset">提交</Button>
                </FormItem>
                <FormItem class="reset-button-group">
                    <Button size="small" type="text" @click.native="$utils.browser.route.jump('/login')">登录</Button>
                    <Button size="small" type="text" @click.native="$utils.browser.route.jump('/register')">注册
                    </Button>
                </FormItem>
            </Form>
        </Card>
    </div>
</template>

<script>
    import Crypto from 'crypto';

    export default {
        name: "reset",
        data() {
            return {
                phone: "",
                code: "",
                password: "",
                codeTips: "获取验证码",
                smsTimer: 0
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
            async reset() {
                let request = {}
                request.phone = this.phone;
                request.code = this.code;
                request.pwd_new = Crypto.createHash("md5").update(this.password).digest('hex');
                let response = await this.$api.auth.reset({}, request).catch(error => {
                    this.$Message.error("重置失败");
                    console.log(error)
                });
                let user_profile = {};
                if (response) {
                    user_profile.username = request.phone;
                    user_profile.state = true;
                    this.$Message.success("重置成功");
                    await this.$utils.browser.route.jump('/login');
                } else {
                    this.$Message.error("重置失败");
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

    .reset-background {
        width: 100%;
        height: 100%;
        line-height: 100%;
        position: absolute;
        bottom: 0;
        left: 0;
        overflow: hidden;
    }

    .reset-background img {
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

    .reset-card {
        width: 320px;
        height: 400px;
    }

    .reset-button-group {
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
    }
</style>