import utils from './index'

const install = function (Vue) {
    if (install.installed) {
        return;
    }

    install.installed = true;
    Object.defineProperties(Vue.prototype, {
        $utils: {
            get() {
                return utils
            }
        }
    })
};

export default {
    install
};
