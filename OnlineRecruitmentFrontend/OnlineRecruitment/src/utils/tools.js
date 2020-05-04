const objectExtend = function (o, n, overwrite = false) {
    for (const p in n) {
        if (overwrite)
            o[p] = n[p];
        else if (n.hasOwnProperty(p) && (!o.hasOwnProperty(p)))
            o[p] = n[p];
    }
    return o
};

const numberFormat = function (number) {
    if (number.toString().length >= 7) {
        return (number / 1000 / 1000).toFixed(3).slice(0, -2) + 'M'
    } else if (number.toString().length >= 4) {
        return (number / 1000).toFixed(3).slice(0, -2) + 'K'
    } else {
        return number
    }
};

const clearObjectValue = function (object) {
    if (!object) return;
    for (let key in object) {
        if (object.hasOwnProperty(key)) {
            if (Array.isArray(object[key]) || typeof object[key] === "object") {
                object[key].forEach(obj => clearObjectValue(obj))
            } else if (typeof object[key] === "string") {
                object[key] = ""
            } else if (typeof object[key] === "number") {
                object[key] = -1
            } else if (typeof object[key] === "boolean") {
                object[key] = false
            }
        }
    }
};

const deepCopy = function (object) {
    let str = JSON.stringify(object);
    return JSON.parse(str)
};

export default {
    objectExtend: objectExtend,
    numberFormat: numberFormat,
    clearObjectValue: clearObjectValue,
    deepCopy: deepCopy
}