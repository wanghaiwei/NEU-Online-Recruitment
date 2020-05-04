import globalFlags from './index'

const install = function (Vue) {
    if (install.installed) {
        return;
    }

    install.installed = true;
    Object.defineProperties(Vue.prototype, {
        $globalFlags: {
            get() {
                return globalFlags
            }
        }
    })
};

export default {
    install
};
