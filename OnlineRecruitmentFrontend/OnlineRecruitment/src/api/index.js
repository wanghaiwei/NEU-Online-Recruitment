import axios from './axios'

let instance = axios();

export default {
    get(url, params, headers, option) {
        let options = option || {};

        if (params) {
            options.params = params
        }
        if (headers) {
            options.headers = headers
        }
        return instance.get(url, options)
    },
    post(url, data, params, headers, option) {
        let options = option || {};

        if (params) {
            options.params = params
        }
        if (headers) {
            options.headers = headers
        }
        return instance.post(url, data, options)
    },
    put(url, params, headers, option) {
        let options = option || {};

        if (headers) {
            options.headers = headers
        }
        return instance.put(url, params, options)
    },
    delete(url, params, headers, option) {
        let options = option || {};

        if (params) {
            options.params = params
        }
        if (headers) {
            options.headers = headers
        }
        return instance.delete(url, options)
    }
}
