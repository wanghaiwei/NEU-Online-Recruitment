import PerfectScrollbar from 'perfect-scrollbar';
import 'perfect-scrollbar/css/perfect-scrollbar.css';

import tools from './tools'
import UA from './browser/UA'

let scrollbar = null;
let container_name = null;

const default_options = {
    suppressScrollX: true,
    wheelSpeed: 1,
    wheelPropagation: true
};

const default_options_chrome = {
    suppressScrollX: true,
    wheelSpeed: 0.47,
    wheelPropagation: true,
};

function initialise(element, options = {}, outerElementWidth, outerElementHeight) {
    options = tools.objectExtend(options, UA.browser.versions.webKit ? default_options_chrome : default_options);
    scrollbar = new PerfectScrollbar(element, options);
    container_name = element;
    if (container_name != null && container_name !== '') {
        const container = document.querySelector(container_name);
        container.parentNode.style.width = outerElementWidth || '100vw';
        container.parentNode.style.height = outerElementHeight || '100vh';
        container.parentNode.style.position = 'relative';
        container.parentNode.style.overflow = 'hidden !important';
        document.body.style.overflow = 'hidden !important';
        container.style.height = outerElementHeight || '100%';
        container.style.width = outerElementWidth || '100%';
        container.style.position = 'relative';
    }
}

function updateContainer() {
    scrollbar?.update()
}

function destroy() {
    scrollbar?.destroy();
    scrollbar = null;
}

function scrollTo(position) {
    if (container_name != null && container_name !== '') {
        const container = document.querySelector(container_name);
        container.scrollTop = position;
    }
}

export default {
    initialise,
    updateContainer,
    destroy,
    scrollTo
}