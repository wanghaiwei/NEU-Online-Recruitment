const phoneRegExp = /^(?:\+?86)?1(?:3\d{3}|5[^4\D]\d{2}|8\d{3}|7(?:[01356789]\d{2}|4(?:0\d|1[0-2]|9\d))|9[189]\d{2}|6[567]\d{2}|4(?:[14]0\d{3}|[68]\d{4}|[579]\d{2}))\d{6}$/;

const phoneWithSMSOnlyRegExp = /^(?:\+?86)?1(?:3\d{3}|5[^4\D]\d{2}|8\d{3}|7(?:[01356789]\d{2}|4(?:0\d|1[0-2]|9\d))|9[189]\d{2}|6[567]\d{2}|4[579]\d{2})\d{6}$/;

const phoneChinaMobile = /^(?:\+?86)?1(?:3(?:4[^9\D]|[5-9]\d)|5[^3-6\D]\d|8[23478]\d|(?:78|98)\d)\d{7}$/;

const phoneChinaUnicom = /^(?:\+?86)?1(?:3[0-2]|[578][56]|66)\d{8}$/;

const phoneChinaTelecom = /^(?:\+?86)?1(?:3(?:3\d|49)\d|53\d{2}|8[019]\d{2}|7(?:[37]\d{2}|40[0-5])|9[19]\d{2})\d{6}$/;

const phoneReg = {
    phoneRegExp,
    phoneWithSMSOnlyRegExp,
    phoneChinaMobile,
    phoneChinaUnicom,
    phoneChinaTelecom
};

/**
 * @param {Object,String} value
 * @param {RegExp} phoneRegRule
 */
const phoneTest = function (value, phoneRegRule) {
    if (typeof phoneRegRule == "undefined" || !phoneRegRule.toString() in phoneReg)
        phoneRegRule = phoneReg.phoneRegExp;
    else {
        if (typeof phoneRegRule == "string")
            phoneRegRule = phoneReg[phoneRegRule]
    }


    if ("region" in value && "number" in value) {
        return phoneRegRule.test(value.number)
    } else {
        return phoneRegRule.test(value)
    }
};

export default {
    phoneTest: phoneTest,
    phoneReg: phoneReg
}