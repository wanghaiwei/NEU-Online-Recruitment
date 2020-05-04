<!--suppress ALL -->
<template>
    <Menu mode="horizontal" theme="dark" :active-name="active_name" @on-select="updateMenu">
        <div class="header-logo"></div>
        <div class="header-nav">
            <MenuItem name="position">
                <Icon type="ios-navigate"></Icon>
                职位
            </MenuItem>
            <MenuItem name="group">
                <Icon type="ios-keypad"></Icon>
                圈子
            </MenuItem>
        </div>
        <div class="header-user">
            <Avatar v-if="!isLogin" icon="ios-person" @click="this.$utils.browser.route.jump('/login')"/>
            <Dropdown v-else>
                <Avatar src=""/>
                <DropdownMenu slot="list">
                    <DropdownItem>个人中心</DropdownItem>
                    <DropdownItem>退出</DropdownItem>
                </DropdownMenu>
            </Dropdown>
        </div>

    </Menu>
</template>

<script>
    export default {
        name: "NavBar",
        watch: {
            "$route"(to, from) {
                console.log(to)
                if (to.path === '/' || to.path === '/index') {
                    this.active_name = "position"
                } else if (to.path === '/group') {
                    this.active_name = "group"
                }
            }
        },
        computed: {
            isLogin: function () {
                return this.$store.getters["auth/LoginState"]
            },
            userAvatar() {
                return this.$store.getters['auth/Avatar']
            },
        },
        data() {
            return {
                active_name: "position",
            }
        },
        methods: {
            updateMenu(route) {
                if (route === 'position') {
                    this.active_name = 'position'
                    this.$utils.browser.route.jump('/')
                } else if (route === 'group') {
                    this.active_name = 'group'
                    this.$utils.browser.route.jump('/group')
                } else if (route === 'user') {
                    this.active_name = ''
                    this.$utils.browser.route.jump('/user')
                } else {
                    this.active_name = ''
                }
            },
        },
        mounted() {
        }
    }
</script>

<style scoped>
    .header-logo {
        width: 105px;
        height: 30px;
        background-image: url("~@assets/pictures/logo.png");
        background-size: cover;
        border-radius: 3px;
        float: left;
        position: relative;
        top: 15px;
        left: 20px;
    }

    .header-nav {
        width: 240px;
        margin: 0 auto;
        margin-left: 120px;
    }

    .header-user {
        width: 64px;
        margin: 0 auto;
        margin-right: 20px;
        cursor: pointer;
    }
</style>