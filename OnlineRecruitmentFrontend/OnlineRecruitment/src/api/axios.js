import axios from 'axios'
import {Message} from "element-ui";
import route from "../utils/browser/jump"

// 创建 axios 实例
let service = axios.create({
    timeout: 60000,
    withCredentials: true, //允许携带cookie
    validateStatus: function (status) {
        return status < 500
    }
});

// 设置 post、put 默认 Content-Type
service.defaults.headers.post['Content-Type'] = 'application/json';
service.defaults.headers.put['Content-Type'] = 'application/json';

// 添加请求拦截器
service.interceptors.request.use(
    (config) => {
        // 请求发送前处理
        if (config.method === 'post' || config.method === 'put') {
        }
        return config
    },
    (error) => {
        // 请求错误处理
        return Promise.reject(error)
    }
);

// 添加响应拦截器
service.interceptors.response.use(
    (response) => {
        let {data} = response;
        if (data.status !== 0) {
            Message({
                showClose: true,
                duration: 3000,
                message: `${data.data.message}`,
                type: 'warning'
            });
            return Promise.reject(data.data);
        }
        return Promise.resolve(data.data);
    },
    async (error) => {
        //响应分享链接404状态码
        if (error.response.status === 404)
            await route.jump(`/404`);

        //Normal operation
        let info = {},
            {status, msg, data, statusText} = error.response;
        if (!error.response) {
            info = {
                code: -1,
                msg: '网络开小差了',
                statusText: statusText
            }
        } else {
            info = {
                code: status,
                data: data,
                msg: msg,
                statusText: statusText
            }
        }
        if (status >= 500) {
            Message({
                showClose: true,
                duration: 1500,
                message: `${status}: ${statusText}`,
                type: 'error'
            });
            return Promise.reject(error.response)
        } else {
            Message({
                showClose: true,
                duration: 1500,
                message: `${status}: ${statusText}`,
                type: 'error'
            });
            return Promise.reject(info)
        }
    }
);

/**
 * 创建统一封装过的 axios 实例
 * @return {AxiosInstance}
 */
export default function () {
    return service
}
