import globalFlags from '../globalFlags/index'

let apiPrefix = globalFlags.apiPrefix;

let baseUrl = 'http://localhost/'; // 本地代理

switch (process.env.NODE_ENV) {
    case 'development':
        //TODO fix test url
        baseUrl = ''; // 测试环境url
        break;
    case 'production':
        //TODO fix test url
        baseUrl = ''; // 生产环境url
        break
}

let fullUrl = baseUrl + apiPrefix;

export default fullUrl
