<!--suppress ALL -->
<template>
    <div class="side">
        <Menu :active-name="active" @on-select="onSelect">
            <MenuGroup title="个人首页">
                <MenuItem name="userProfile">
                    <Icon type="md-document"/>
                    个人资料
                </MenuItem>
                <MenuItem name="postPosition">
                    <Icon type="md-chatbubbles"/>
                    发布职位
                </MenuItem>
            </MenuGroup>
            <MenuGroup title="身份认证">
                <MenuItem name="authentication">
                    <Icon type="md-heart"/>
                    身份认证
                </MenuItem>
            </MenuGroup>
        </Menu>
    </div>
</template>

<script>
    export default {
        name: "Sidebar",
        data() {
            return {
                active: "userProfile"
            }
        },
        methods: {
            onSelect(name) {
                switch (name) {
                    case "userProfile":
                        this.$utils.browser.route.jump("/user/detail");
                        break;
                    case "postPosition":
                        this.$utils.browser.route.jump("/user/add/position");
                        break;
                    case "authentication":
                        this.$utils.browser.route.jump("/user/auth");
                        break;
                }
            },
        },
        mounted() {
            let active = this.$route.path;
            switch (name) {
                case "/user/detail":
                    this.active = "userProfile";
                    break;
                case "/user/add/position":
                    this.active = "postPosition";
                    break;
                case "/user/auth":
                    this.active = "authentication";
                    break;
            }
        }
    }
</script>

<style scoped>
    .side {
        padding: 8px 16px;
    }
</style>