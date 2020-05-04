import browser from './browser'
import tools from './tools'
import scrollbar from './scrollbar'
import RegExp from './RegExp'

Array.prototype.remove = function (val) {
    const index = this.indexOf(val);
    if (index > -1) {
        this.splice(index, 1);
    }
};

export default {
    browser,
    tools,
    scrollbar,
    RegExp,
}