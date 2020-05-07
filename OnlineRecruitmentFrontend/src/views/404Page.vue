<!--suppress ALL -->
<template>
    <div>
        <div class="whole">
            <img alt="" src="~@assets/pictures/background.jpg"/>
            <div class="mask"></div>
        </div>
        <div class="tip">
            <img alt="" class="center nf-img" src="~@assets/pictures/404.png"/>
            <p>
                暂时未能找到您查找的页面<br>
                可能输入的网址错误或此页面不存在<br>
                <span>{{time}}</span>秒后自动跳转到主页
            </p>
        </div>
    </div>
</template>

<script>
    export default {
        name: "NotFound",
        data() {
            return {
                timer: '',
                time: 5
            }
        },
        methods: {
            redirect() {
                this.time--;
                if (this.time < 0) {
                    this.time = 0;
                    this.$utils.browser.route.jump('/index')
                }
            }
        },
        mounted() {
            this.timer = setInterval(this.redirect, 1000);
        },
        beforeDestroy() {
            clearInterval(this.timer);
        }
    }
</script>

<style lang="scss" scoped>
    .center {
        margin: 0 auto;
    }

    .whole {
        width: 100%;
        height: 100%;
        line-height: 100%;
        position: absolute;
        bottom: 0;
        left: 0;
        overflow: hidden;
    }

    .whole img {
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

    .tip {
        width: 100%;
        text-align: center;
        height: 400px;
        position: absolute;
        top: 50%;
        margin-top: -230px
    }

    #num {
        margin: 0 5px;
        font-weight: bold;
    }

    p {
        color: #fff;
        margin-top: 40px;
        @media screen and (min-width: 360px) {
            font-size: 18px;
        }
        @media screen and (min-width: 960px) {
            font-size: 24px;
        }
        line-height: 56px;

        span {
            margin: 0 5px;
            font-weight: bold;
        }
    }
</style>