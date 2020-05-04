<!--suppress ALL -->
<template>
    <el-header class="top-nav">
        <el-container>
            <div @click="$utils.browser.route.jump('/')" class="nav-logo-content">
                <el-image :src="require('@assets/pictures/logo.png')" class="nav-logo">
                    <div class="image-slot" slot="error">
                        <img class="ercode-img" src="@assets/pictures/login/ercode-placehold.png"/>
                    </div>
                </el-image>
            </div>
            <div class="nav-split"></div>
            <el-menu :default-active="active_item" class="nav-menu" mode="horizontal">
                <el-menu-item @click="$utils.browser.route.jump(current_path)" index="menu_item_1">
                    {{first_active_item_title}}
                </el-menu-item>
                <el-menu-item @click="$utils.browser.route.jump('/info')" index="menu_item_2">信息</el-menu-item>
                <el-menu-item @click="$utils.browser.route.jump('/explore')" index="menu_item_3">问答</el-menu-item>
                <div class="nav-right">
                    <el-dropdown @command="$utils.browser.route.jump">
                        <el-avatar class="nav-avatar">
                            <i class="nav-avatar-size el-icon-extend-user" v-if="!isLogin || avatarUrl == ''"></i>
                            <el-image :src="avatarUrl" class="nav-avatar-size" v-else>
                                <div class="image-slot" slot="error">
                                    <i class="el-icon-picture-outline"></i>
                                </div>
                            </el-image>
                        </el-avatar>
                        <el-dropdown-menu slot="dropdown" v-if="!isLogin">
                            <el-dropdown-item command="/login">登陆</el-dropdown-item>
                            <el-dropdown-item command="/register">注册</el-dropdown-item>
                        </el-dropdown-menu>
                        <el-dropdown-menu slot="dropdown" v-else>
                            <el-dropdown-item :command="`/personal/${currentUser}`">个人资料
                            </el-dropdown-item>
                            <el-dropdown-item @click.native="logout">退出</el-dropdown-item>
                        </el-dropdown-menu>
                    </el-dropdown>
                </div>
                <div :data-show="searchIcon ? 'inactive': 'active'" class="nav-right nav-icon" v-if="false">
                    <el-badge :max="9" :value="badge" class="item" v-if="badge != 0">
                        <i class="icon-font-size el-icon-bell"></i>
                    </el-badge>
                    <i class="icon-font-size el-icon-extend-notification" v-else></i>
                </div>
                <div :data-show="searchIcon ? 'inactive': 'active'" class="nav-right nav-icon" v-if="false">
                    <i class="icon-font-size el-icon-extend-service"></i>
                </div>
                <div :data-show="searchIcon ? 'inactive': 'active'" @click="showSearchBox"
                     class="nav-right nav-icon nav-icon-search">
                    <i class="icon-font-size el-icon-extend-sousuo" v-if="searchIcon"></i>
                    <transition name="open-search">
                        <el-input @blur="showSearchIcon" placeholder="请输入内容" prefix-icon="el-icon-extend-sousuo"
                                  ref="searchBox" v-if="searchBox" v-model="search"/>
                    </transition>
                </div>
            </el-menu>
        </el-container>
    </el-header>
</template>

<script>
    import {mapGetters} from 'vuex'

    export default {
        name: "NavBar",
        watch: {
            "$route"(to, from) {
                this.judgeRouter(to)
            }
        },
        data() {
            return {
                first_active_item_title: "首页",
                active_item: "1",
                //搜索相关
                search: "",
                searchBox: false,
                searchIcon: true,
                //消息提醒数值
                badge: 0,
                //当前路径
                current_path: ""
            }
        },
        computed: {
            ...mapGetters({isLogin: "auth/LoginState", avatarUrl: "auth/UserAvatar", currentUser: "auth/CurrentUser"}),
        },
        methods: {
            showSearchBox() {
                if (!this.searchBox) {
                    this.searchBox = true
                    this.searchIcon = false
                    this.$nextTick(() => this.$refs.searchBox.focus()
                    )
                }
            },
            showSearchIcon() {
                if (!this.searchIcon) {
                    this.searchBox = false
                    setTimeout(() => {
                        this.searchIcon = true
                    }, 200)
                }
            },
            judgeRouter(route) {
                if (route.path === '/info') {
                    this.active_item = 'menu_item_2'
                    this.current_path = "/"
                    this.first_active_item_title = "首页"
                } else if (route.path === '/explore') {
                    this.active_item = 'menu_item_3'
                    this.current_path = "/"
                    this.first_active_item_title = "首页"
                } else {
                    this.active_item = 'menu_item_1'
                    this.current_path = route.path
                    if ("title" in route.meta)
                        this.first_active_item_title = route.meta.title.replace("", "")
                }
            },
            async logout() {
                await this.$api.auth.logout();
                await this.$store.dispatch("auth/changeLogin", {
                    state: false,
                    username: ""
                });
                await this.$utils.browser.route.jump(`/`);
                this.$message({
                    showClose: true,
                    message: "已退出",
                    type: 'success'
                })
            }
        },
        created() {
            this.current_path = '/'
            this.judgeRouter(this.$route);
        }
    }
</script>

<style lang="scss" scoped>
    .top-nav {
        position: fixed;
        z-index: 1001;
        padding: $--header-padding;
        border-bottom: solid 1px #e6e6e6;
        background: #fff;
    }

    .nav-logo-content {
        height: $nav-height - 1px;
        background: #fff;
        cursor: pointer;
    }

    .nav-logo {
        height: $logo-size-height;
        width: $logo-size-width;
        padding: {
            right: nth($--header-padding, 2);
            top: ($nav-height - $logo-size-height) / 2;
            bottom: ($nav-height - $logo-size-height) / 2;
        };
    }

    .nav-menu {
        height: $nav-height - 1px;
        padding: {
            left: nth($--header-padding, 2);
        };
        @include resolution() {
            $nav-width: calc(100vw - #{$logo-size-width + $--main-page-padding * 2 + nth($--header-padding, 2) * 4});
            width: $nav-width;
        }
    }

    .nav-split {
        border-left: 1px solid #ccc;
        height: $nav-height - 1px - 16px * 2;
        margin: 16px 0;
    }

    .nav-right {
        float: right;
        height: $nav-height - 1px;
        margin: 0 12px;
    }

    .nav-avatar {
        margin: ($nav-height - 1px - $--avatar-large-size) / 2 0;
    }

    .nav-avatar-size {
        height: $--avatar-large-size;
        width: $--avatar-large-size;
        font-size: $--nav-avatar-font-size;
        line-height: $--avatar-large-size;
    }

    .nav-icon {
        height: $icon-size;
        width: $icon-size;
        margin: ($nav-height - 1px - $icon-size) / 2 12px;
    }

    .nav-icon-search[data-show="active"] {
        width: $searchBoxWidth;
        height: $searchBoxHeight;
        margin: ($nav-height - 1px - $searchBoxHeight) / 2 12px;
    }

    .icon-font-size {
        font-size: $--icon-font-size;
    }

    .open-search-enter-active, .open-search-leave-active {
        transition: all .4s;
        float: right;
    }

    .open-search-enter {
        transform: translate3d($icon-size, 0, 0);
        width: $searchBoxWidth;
        height: $searchBoxHeight;
        opacity: 0;
    }

    .open-search-leave-active {
        transform: translate3d($icon-size, 0, 0);
        width: $icon-size;
        height: $icon-size;
        opacity: 0;
    }
</style>